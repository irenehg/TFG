`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.04.2023 21:18:32
// Design Name: 
// Module Name: operations
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


module operations(
    input i_clk,
    input [71:0] i_pixel_data,
    input i_pixel_valid,
    output reg [7:0] o_result_pixel,
    output reg o_result_valid
    );
    
 reg [7:0] kernel [8:0];
 integer i;  
 reg [15:0] multiplication_result [8:0];
 reg [15:0] add_result_aux;
 reg [15:0] add_result;
 reg add_valid;
 reg mult_valid;
  
 
 //Valores del kernel no van a cambiarse
 initial
 begin
    kernel[0] = 1;
    kernel[1] = 1;
    kernel[2] = 1;
    kernel[3] = 1;
    kernel[4] = 1;
    kernel[5] = 1;
    kernel[6] = 1;
    kernel[7] = 1;
    kernel[8] = 1;
 end
 
 always @(posedge i_clk)
 begin
 // -------------------------- MULTIPLICACION -------------------------- //
    for(i=0; i<9; i=i+1)
    begin
      multiplication_result[i] <= kernel[i]*i_pixel_data[i*8+:8]; 
    end
    mult_valid <= i_pixel_valid; 
 end   
    
 // -------------------------- SUMA -------------------------- //
 //Lo ponemos en un bloque distinto a la multiplicacion porque no se pueden mezclar < y <=
 always @(*)
 begin
   add_result_aux = 0; 
   
   for(i=0; i<9; i=i+1)
   begin
     add_result_aux = add_result_aux + multiplication_result[i]; 
   end
 end
 
  always @(posedge i_clk)
  begin
    add_result <= add_result_aux;
    add_valid <= mult_valid;      
  end  
  
// -------------------------- DIVISION BOX BLUR FILTER -------------------------- //  
 always @(posedge i_clk)
 begin
     o_result_pixel <= add_result/9; //Se queda con la parte entera de la division
     o_result_valid <= add_valid;
 end  

endmodule
