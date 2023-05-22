`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.02.2023 18:30:50
// Design Name: 
// Module Name: lineBuffer
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


module lineBuffer(
    input i_clk,
    input i_rst,
    input [7:0] i_data,
    input i_data_valid,
    output [23:0] o_data, //kernel 3x3 -> 3x8bits=24
    input i_rd_data //read signal from slave, indica que se han leido datos del line buffer
);

reg [7:0] line [511:0]; //este es el line buffer donde almacenamos la imagen
reg [8:0] wrPointer;
reg [8:0] rdPointer;


// ----------------------- ESCRITURA EN EL LINE BUFFER ----------------------- //
always @(posedge i_clk)
begin 
    //Cuando llega un nuevo pixel de entrada necesitamos saber donde se va a guardar en la memoria
    if(i_data_valid)
        line[wrPointer] <= i_data;
end

//Modificacion posicion del puntero wrPointer
always @(posedge i_clk)
begin
    if(i_rst)
        wrPointer <= 'd0;
    else if(i_data_valid)
        wrPointer <= wrPointer + 'd1;
end



// ----------------------- LECTURA DEL LINE BUFFER ----------------------- //
//Concatenamos aqui fuera del always (combinacional) los pixeles para evitar latencia de 
//lectura del o_data con la señal i_rd_data  
assign o_data = {line[rdPointer], line[rdPointer+1], line[rdPointer+2]};

always @(posedge i_clk)
begin
    if(i_rst)
        rdPointer <= 'd0; 
    else if(i_rd_data)
        rdPointer <= rdPointer + 'd1;
end

endmodule
