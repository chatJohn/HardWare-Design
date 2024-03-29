module mycpu_top(
    input  wire [5 : 0] ext_int,  //high active

    input  wire         aclk,    
    input  wire         aresetn,  //low active

    output wire [3 : 0] arid,
    output wire [31: 0] araddr,
    output wire [7 : 0] arlen,
    output wire [2 : 0] arsize,
    output wire [1 : 0] arburst,
    output wire [1 : 0] arlock,
    output wire [3 : 0] arcache,
    output wire [2 : 0] arprot,
    output wire         arvalid,
    input  wire         arready,

    input  wire [3 : 0] rid,
    input  wire [31: 0] rdata,
    input  wire [1 : 0] rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output wire         rready, 

    output wire [3 : 0] awid,
    output wire [31: 0] awaddr,
    output wire [7 : 0] awlen,
    output wire [2 : 0] awsize,
    output wire [1 : 0] awburst,
    output wire [1 : 0] awlock,
    output wire [3 : 0] awcache,
    output wire [2 : 0] awprot,
    output wire         awvalid,
    input  wire         awready,

    output wire [3 : 0] wid,
    output wire [31: 0] wdata,
    output wire [3 : 0] wstrb,
    output wire         wlast,
    output wire         wvalid,
    input  wire         wready,
    
    input  wire [3 : 0] bid,
    input  wire [1 : 0] bresp,
    input  wire         bvalid,
    output wire         bready,

    //debug interface
    output wire [31: 0] debug_wb_pc,
    output wire [3 : 0] debug_wb_rf_wen,
    output wire [4 : 0] debug_wb_rf_wnum,
    output wire [31: 0] debug_wb_rf_wdata
);

    wire clk, rst;
    assign clk = aclk;
    assign rst = ~aresetn;

    wire         cpu_inst_req  ;
    wire [31: 0] cpu_inst_addr ;
    wire         cpu_inst_wr   ;
    wire [1 : 0] cpu_inst_size ;
    wire [31: 0] cpu_inst_wdata;
    wire [31: 0] cpu_inst_rdata;
    wire         cpu_inst_addr_ok;
    wire         cpu_inst_data_ok;

    wire         cpu_data_req  ;
    wire [31: 0] cpu_data_addr ;
    wire         cpu_data_wr   ;
    wire [1 : 0] cpu_data_size ;
    wire [31: 0] cpu_data_wdata;
    wire [31: 0] cpu_data_rdata;
    wire         cpu_data_addr_ok;
    wire         cpu_data_data_ok;

    mips_core mips_core(
        .clk(clk), 
        .rst(rst),
        .ext_int(ext_int),

        .inst_req     (cpu_inst_req  ),
        .inst_wr      (cpu_inst_wr   ),
        .inst_addr    (cpu_inst_addr ),
        .inst_size    (cpu_inst_size ),
        .inst_wdata   (cpu_inst_wdata),
        .inst_rdata   (cpu_inst_rdata),
        .inst_addr_ok (cpu_inst_addr_ok),
        .inst_data_ok (cpu_inst_data_ok),

        .data_req     (cpu_data_req  ),
        .data_wr      (cpu_data_wr   ),
        .data_addr    (cpu_data_addr ),
        .data_wdata   (cpu_data_wdata),
        .data_size    (cpu_data_size ),
        .data_rdata   (cpu_data_rdata),
        .data_addr_ok (cpu_data_addr_ok),
        .data_data_ok (cpu_data_data_ok),

        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata )
    );

    wire [31:0] cpu_inst_paddr;
    wire [31:0] cpu_data_paddr;
    wire no_dcache;

    mmu mmu(
        .inst_vaddr(cpu_inst_addr ),
        .inst_paddr(cpu_inst_paddr),
        .data_vaddr(cpu_data_addr ),
        .data_paddr(cpu_data_paddr),
        .no_dcache (no_dcache    )
    );


    cpu_axi_interface cpu_axi_interface(
        .clk(clk),
        .resetn(~rst),

        .inst_req       (cpu_inst_req  ),
        .inst_wr        (cpu_inst_wr   ),
        .inst_size      (cpu_inst_size ),
        .inst_addr      (cpu_inst_paddr ),
        .inst_wdata     (cpu_inst_wdata),
        .inst_rdata     (cpu_inst_rdata),
        .inst_addr_ok   (cpu_inst_addr_ok),
        .inst_data_ok   (cpu_inst_data_ok),

        .data_req       (cpu_data_req  ),
        .data_wr        (cpu_data_wr   ),
        .data_size      (cpu_data_size ),
        .data_addr      (cpu_data_paddr ),
        .data_wdata     (cpu_data_wdata),
        .data_rdata     (cpu_data_rdata),
        .data_addr_ok   (cpu_data_addr_ok),
        .data_data_ok   (cpu_data_data_ok),

        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arlock(arlock),
        .arcache(arcache),
        .arprot(arprot),
        .arvalid(arvalid),
        .arready(arready),

        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready),

        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awlock(awlock),
        .awcache(awcache),
        .awprot(awprot),
        .awvalid(awvalid),
        .awready(awready),

        .wid(wid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),

        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );




    // wire [31:0] inst_vaddr,inst_paddr;
    // wire [31:0] data_vaddr,data_paddr;
    // wire no_dcache;
    // mmu mmu(inst_vaddr,inst_paddr,data_vaddr,data_paddr,no_dcache);

    // wire [31:0] pc;
	// wire [31:0] instr;
	// wire [3:0] memwrite;
	// wire [31:0] aluout, writedata, readdata;
    // wire [31:0] pc_W;
	// wire RegWrite_W;
	// wire [4:0] write_reg_W;
	// wire [31:0] result_W;
    // mips mips(
    //     .clk(~clk),
    //     .rst(~resetn),
        
    //     .pcF(pc),
    //     .instrF(instr),
        
    //     //data
    //     .memwriteM(memwrite),
    //     .aluoutM(aluout),
    //     .writedataM(writedata),
    //     .readdataM(readdata),
        
    //     //debug
    //     .pc_W(debug_wb_pc),
    //     .RegWrite_W(RegWrite_W),
    //     .write_reg_W(write_reg_W),
    //     .result_W(result_W)
    // );

    // assign inst_sram_en      = 1'b1;
    // assign inst_sram_wen     = 4'b0;
    // assign inst_sram_addr    = inst_paddr;
    // assign inst_sram_wdata   = 32'b0;
    // assign instr             = inst_sram_rdata;

    // assign inst_vaddr        = pc;
    // assign data_vaddr        = {aluout[31:2], 2'b00};

    // assign data_sram_en      = 1'b1;
    // assign data_sram_wen     = memwrite;
    // assign data_sram_addr    = data_paddr;
    // assign data_sram_wdata   = writedata;
    // assign readdata          = data_sram_rdata;

    // assign debug_wb_pc       = pc_W;
    // assign debug_wb_rf_wen   = {4{RegWrite_W}};
    // assign debug_wb_rf_wnum  = write_reg_W;
    // assign debug_wb_rf_wdata = result_W;

    //ascii
    instdec instdec(
        .instr(cpu_inst_rdata)
    );


endmodule
