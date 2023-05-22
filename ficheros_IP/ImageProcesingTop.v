`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.05.2023 20:30:17
// Design Name: 
// Module Name: ImageProcesingTop
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ImageProcesingTop(
    input axi_clk,
    input axi_reset_n, //se pone n porque el reset del AXI es active-low. Lo invertiremos
    //slave interface, datos procedentes del DMA controller 
    input i_data_valid,
    input [7:0] i_data, //pixel 
    output o_data_ready, //se manda al DMA controller cuando recibes datos de él
    //master interface, devuelve los datos al DMA controller (imagen convertida)
    output o_data_valid,
    output [7:0] o_data,
    input i_data_ready, //se recibe del DMA controller cuando le mandamos datos
    //señal de interrupcion
    output o_interrupt  // Se manda cuando se ha procesado una fila entera y se queda un linebuffer disponible 
 );
    
    wire [71:0] pixel_data; //Lo que sale del ImgControl es lo que entra en el Operations
    wire pixel_valid;
    wire [7:0] changed_data;
    wire changed_data_valid;
    wire axis_prog_full;
    
    assign o_data_ready = !axis_prog_full;

 // -------------------------- INSTANCIAMOS IMGCONTROL -------------------------- //

 imgControl ImgCtrl(.i_clk(axi_clk), .i_rst(!axi_reset_n), .i_pixel(i_data), .i_pixel_valid(i_data_valid), 
                    .o_pixel(pixel_data), .o_pixel_valid(pixel_valid), .o_interrupt(o_interrupt));


 // -------------------------- INSTANCIAMOS OPERATIONS -------------------------- //

 operations Op(.i_clk(axi_clk), .i_pixel_data(pixel_data), .i_pixel_valid(pixel_valid), 
               .o_result_pixel(changed_data), .o_result_valid(changed_data_valid)); 
  
  
  // -------------------------------- OUTPUT BUFFER -------------------------------- //
  
 //La salida del operations se va a almacenar en el FIFO y ya desde aqui se manda a la salida real 
 //Cuando el FIFO este casi lleno (i_data_ready=0) se queda la info en el FIFO y no se pierde nada 
 //IP sources -> Instantiation Template -> outputBuffer.veo              
 outputBuffer oBuffer (
  .wr_rst_busy(),        // output wire wr_rst_busy
  .rd_rst_busy(),        // output wire rd_rst_busy
  .s_aclk(axi_clk),                  // input wire s_aclk
  .s_aresetn(axi_reset_n),            // input wire s_aresetn
  .s_axis_tvalid(changed_data_valid),    // input wire s_axis_tvalid
  .s_axis_tready(),    // output wire s_axis_tready
  .s_axis_tdata(changed_data),      // input wire [7 : 0] s_axis_tdata
  .m_axis_tvalid(o_data_valid),    // output wire m_axis_tvalid
  .m_axis_tready(i_data_ready),    // input wire m_axis_tready
  .m_axis_tdata(o_data),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);              
 
endmodule