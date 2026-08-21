import hsdaro_pkg::*;
module hsdaro_hwpe_top(
    input i_clk,
    input i_resetn,
    hwpe_ctrl_if_pheriph.slave hsdaro_hwpe_ctrl_if
);

    logic [HSDARO_REG_W-1:0] r_hsdaro_ctrl;
    logic [HSDARO_REG_W-1:0] r_hsdaro_status;
    logic [HSDARO_REG_W-1:0] r_hsdaro_weights_start_addr;
    logic [HSDARO_REG_W-1:0] r_hsdaro_image_start_addr;
     
    logic w_hsdaro_access;
    logic w_hsdaro_write_access;
    logic w_hsdaro_read_access;

    assign hsdaro_hwpe_ctrl_if.gnt = hsdaro_hwpe_ctrl_if.req;
    assign w_hsdaro_access = hsdaro_hwpe_ctrl_if.req && hsdaro_hwpe_ctrl_if.gnt;
    assign w_hsdaro_write_access = w_hsdaro_access &&!hsdaro_hwpe_ctrl_if.wen;
    assign w_hsdaro_read_access = w_hsdaro_access && hsdaro_hwpe_ctrl_if.wen;
    
    always_ff @( posedge i_clk or negedge i_resetn ) begin : REG_WRTIE

        if(!i_resetn) begin
            r_hsdaro_ctrl               <= '0;
            r_hsdaro_status             <= '0;

            r_hsdaro_weights_start_addr <= '0;
            r_hsdaro_image_start_addr   <= '0;
        end else begin
            if(w_hsdaro_write_access) begin
                unique case(hsdaro_hwpe_ctrl_if.add)
                    HSDARO_HWPE_CTRL_REG: begin
                        r_hsdaro_ctrl <= hsdaro_hwpe_ctrl_if.data;
                    end
                    HSDARO_HWPE_STATUS_REG: begin
                       r_hsdaro_status <= hsdaro_hwpe_ctrl_if.data;
                    end
                    HSDARO_HWPE_WEIGHTS_START_ADDR_REG: begin
                        r_hsdaro_weights_start_addr <= hsdaro_hwpe_ctrl_if.data;
                    end
                    HSDARO_HWPE_IMAGE_START_ADDR_REG: begin
                        r_hsdaro_image_start_addr <= hsdaro_hwpe_ctrl_if.data;
                    end
                    default: begin
                        // do nothing
                    end
                endcase
            end
         end
    end

    always_comb begin : REG_READ

        hsdaro_hwpe_ctrl_if.r_data = '0;
        if(w_hsdaro_read_access) begin 
            unique case(hsdaro_hwpe_ctrl_if.add)
                HSDARO_HWPE_CTRL_REG: begin
                    hsdaro_hwpe_ctrl_if.r_data = r_hsdaro_ctrl;
                end
                HSDARO_HWPE_STATUS_REG: begin
                    hsdaro_hwpe_ctrl_if.r_data = r_hsdaro_status;
                end
                HSDARO_HWPE_WEIGHTS_START_ADDR_REG: begin
                    hsdaro_hwpe_ctrl_if.r_data = r_hsdaro_weights_start_addr;
                end
                HSDARO_HWPE_IMAGE_START_ADDR_REG: begin
                    hsdaro_hwpe_ctrl_if.r_data = r_hsdaro_image_start_addr;
                end
                default: begin
                    // do nothing
                end
            endcase
            
        end
    end



endmodule
