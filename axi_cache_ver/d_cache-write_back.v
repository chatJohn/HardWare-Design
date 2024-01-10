module d_cache_write_back (
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
    //Cache����
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
    //Cache�洢��Ԫ
    reg                 cache_valid [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block [CACHE_DEEPTH - 1 : 0];
    reg cache_dirty [CACHE_DEEPTH-1:0]; //cache�Ƿ��ѱ��޸� Ϊ1ʱ��ʾ��

    //���ʵ�ַ�ֽ�
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //����Cache line
    wire c_valid;
    wire [TAG_WIDTH-1:0] c_tag;
    wire [31:0] c_block;
    wire c_dirty;

    assign c_valid = cache_valid[index];
    assign c_tag   = cache_tag  [index];
    assign c_block = cache_block[index];
    assign c_dirty=cache_dirty[index];

    //�ж��Ƿ�����
    wire hit, miss;
assign hit = c_valid & (c_tag == tag);  
//cache line��validλΪ1����tag���ַ��tag���
    assign miss = ~hit;

    //����д
    wire read, write;
    assign write = cpu_data_wr;
    assign read = cpu_data_req & ~write; //���������Ҳ�д
    
    //�����Ƿ��޸�
    wire dirty,clean;
    assign dirty=c_dirty;
    assign clean=~dirty;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg in_RM; //ȷ���Ƿ���RM״̬
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            in_RM<=0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(cpu_data_req)begin//��������
                        if(hit)begin//����
                            state<=IDLE;//һ���ڴ������
                        end
                        else if(miss&dirty)begin//δ�����������ѱ��޸�
                            state<=WM;//����д���ݽ׶� 
                        end
                        else if(miss&clean)begin//δ����������δ����
                            state<=RM;//������׶�
                        end
                    end
                    in_RM<=0;//�����ڶ��׶�
                end
                RM:begin
                    if(cache_data_data_ok)begin//���������
                        state<=IDLE;//�ص�Ĭ��״̬
                    end
                    in_RM<=1;//���ڶ��׶�
                end
                WM:begin
                    if(cache_data_data_ok)begin//д�������
                        state<=RM;//д���
                    end
                end
            endcase
        end
    end

    //���ڴ�
    //����read_req, addr_rcv, read_finish���ڹ�����sram�źš�
    wire read_req;      //һ�������Ķ����񣬴ӷ��������󵽽���
    reg addr_rcv;       //��ַ���ܳɹ�(addr_ok)�󵽽���
    wire read_finish;   //���ݽ��ճɹ�(data_ok)�������������
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    read_req & cache_data_req & cache_data_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : addr_rcv;
    end
    assign read_req = state==RM;
    assign read_finish = read_req & cache_data_data_ok;

    //д�ڴ�
    wire write_req;     
    reg waddr_rcv;      
    wire write_finish;   
    always @(posedge clk) begin
        waddr_rcv <= rst ? 1'b0 :
                     write_req & cache_data_req & cache_data_addr_ok ? 1'b1 :
                     write_finish ? 1'b0 : waddr_rcv;
    end
    assign write_req = state==WM;
    assign write_finish = write_req & cache_data_data_ok;

    //output to mips core
    assign cpu_data_rdata   = hit ? c_block : cache_data_rdata;
    assign cpu_data_addr_ok = cpu_data_req & hit | cache_data_req & read_req & cache_data_addr_ok;
    //��������������           ����ȱʧ   (���࣬��д���ݣ�д������֮��)��������ݽ׶�
    assign cpu_data_data_ok = cpu_data_req & hit | cache_data_data_ok & read_req;
//��������������         ����ȱʧ   (���࣬��д���ݣ�д������֮��)��������ݽ׶�

    //output to axi interface
    assign cache_data_req   = read_req & ~addr_rcv | write_req & ~waddr_rcv;
    assign cache_data_wr    = write_req;
    assign cache_data_size  = cpu_data_size;
    assign cache_data_addr  = cache_data_wr?{c_tag,index,offset}:cpu_data_addr;
    //         д���ڴ�����ݵ�ַ        ԭtag  ��ͬ������  �Ե�ǰƫ����д��
    assign cache_data_wdata = c_block;
    //         д���ڴ������Ϊԭ����

    //д��Cache
    //�����ַ�е�tag, index����ֹaddr�����ı�
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
    end

    wire [31:0] write_cache_data;
    wire [3:0] write_mask;

    //���ݵ�ַ����λ��size,����д���루���sb��sh�Ȳ���д����һ���ֵ�ָ���4λ��1���֣�4�ֽڣ���ÿ���ֵ�дʹ��
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //�����ʹ�ã�λΪ1�Ĵ�����Ҫ���µġ�
    //λ��չ{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data = cache_block[index] & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    wire isIDLE= state==IDLE;
    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //�տ�ʼ��Cache��Ϊ��Ч  ��λ��0
                cache_valid[t] <= 0;
                cache_dirty[t]<=0;
            end
        end
        else begin
            if(read_finish) begin //����ɶ��ڴ��ҵõ�����
                cache_valid[index_save] <= 1'b1;             //��Cache line��Ϊ��Ч
                cache_tag  [index_save] <= tag_save;
                cache_block[index_save] <= cache_data_rdata; //д��Cache line
                cache_dirty[index_save]<=0;//�¶���������Ϊclean
            end
            else if(write & isIDLE & (hit | in_RM)) begin
            // д������       ���з�����IDLE�׶� �� δ���дӶ��ڴ�׶λص�IDLE�׶�
                cache_block[index] <= write_cache_data;      
//д��Cache line��ʹ��index������index_save
                cache_dirty[index]<=1; //д��cacheʱ����λ��1
            end
        end
    end
endmodule
