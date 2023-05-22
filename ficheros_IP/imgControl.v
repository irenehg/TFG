`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.05.2023 19:04:17
// Design Name: 
// Module Name: imgControl
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


module imgControl(
    input i_clk,
    input i_rst,
    input [7:0] i_pixel,
    input i_pixel_valid,
    output reg [71:0] o_pixel, //Si miramos en operations.v vemos que la entrada son los 9 pixeles del tiron 
    output o_pixel_valid,
    output reg o_interrupt
    );
    
 reg [8:0] pixel_wr_count; //El valor maximo va a ser 511, necesitamos 9 bits
 reg [1:0] write_buffer; //El valor maximo va a ser 3, necesitamos 2 bits   
 reg [3:0] lineBuffer_wr_valid; //Cada buffer tendra su señal para indicar que esta activo 
 reg [11:0] total_pixel;
 
 reg [8:0] pixel_rd_count; //Contador pixeles leidos
 reg [1:0] read_buffer; //Buffer seleccionado
 reg [3:0] lineBuffer_rd_valid; // Necesitamos este para saber cual esta activo en lectura
 reg pixel_rd_valid; //Se genera cuando estan escritos los 3 line buffers  que se leen, cuando tenemos 1536 pixeles (3x512)
 reg readState; //Solo tiene dos estados, con 1 bit le sobra
 
 wire [23:0] lineBuffer0_data; // 3 pixeles de 8bits cada uno 
 wire [23:0] lineBuffer1_data;
 wire [23:0] lineBuffer2_data;
 wire [23:0] lineBuffer3_data;
 
  
 localparam IDLE ='b0,
            READ_ACTIVE = 'b1;
 
 assign o_pixel_valid = pixel_rd_valid;
    
// -------------------------- INSTANCIAMOS LINEBUFFER -------------------------- //
 lineBuffer lineBuffer0(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel), .i_data_valid(lineBuffer_wr_valid[0]), 
                        .o_data(lineBuffer0_data), .i_rd_data(lineBuffer_rd_valid[0]));
  
 lineBuffer lineBuffer1(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel), .i_data_valid(lineBuffer_wr_valid[1]), 
                        .o_data(lineBuffer1_data), .i_rd_data(lineBuffer_rd_valid[1]));
 
 lineBuffer lineBuffer2(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel), .i_data_valid(lineBuffer_wr_valid[2]), 
                        .o_data(lineBuffer2_data), .i_rd_data(lineBuffer_rd_valid[2]));
 
 lineBuffer lineBuffer3(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel), .i_data_valid(lineBuffer_wr_valid[3]), 
                        .o_data(lineBuffer3_data), .i_rd_data(lineBuffer_rd_valid[3])); 
 
 
 // ------------------ ELECCION DEL LINEBUFFER DONDE ALMACENAR/ESCRIBIR DATOS ------------------ //
 
 always @(posedge i_clk)
 begin
    if(i_rst)
    begin
        pixel_wr_count <= 0;
        write_buffer <= 0;
    end
    else
    begin
        if(i_pixel_valid)
            pixel_wr_count <= pixel_wr_count + 1;
        
        if(pixel_wr_count == 511 & i_pixel_valid)
        begin
            write_buffer <= write_buffer + 1;
            pixel_wr_count <= 0;
        end               
    end    
 end   
 
 always @(*)
 begin
    lineBuffer_wr_valid = 4'h0;
    lineBuffer_wr_valid[write_buffer] = i_pixel_valid;
 end
 
 
 // ------------------ ELECCION DEL LINEBUFFER DE DONDE LEER DATOS ------------------ //
 
 always @(posedge i_clk)
 begin 
    if(i_rst)
    begin
        pixel_rd_count <= 0;
        read_buffer <= 0;
    end
    else
    begin
        if(pixel_rd_valid)
            pixel_rd_count <= pixel_rd_count + 1;
         
        if(pixel_rd_count == 511 & pixel_rd_valid)
        begin
            read_buffer <= read_buffer + 1;
            pixel_rd_count <= 0;
        end               
    end    
 end 
 
 always @(*)
 begin
    case(read_buffer)
        0:begin
            lineBuffer_rd_valid[0] = pixel_rd_valid;
            lineBuffer_rd_valid[1] = pixel_rd_valid;
            lineBuffer_rd_valid[2] = pixel_rd_valid;
            lineBuffer_rd_valid[3] = 1'b0;
        end
        1:begin
            lineBuffer_rd_valid[1] = pixel_rd_valid;
            lineBuffer_rd_valid[2] = pixel_rd_valid;
            lineBuffer_rd_valid[3] = pixel_rd_valid;
            lineBuffer_rd_valid[0] = 1'b0;
        end
        2:begin
            lineBuffer_rd_valid[2] = pixel_rd_valid;
            lineBuffer_rd_valid[3] = pixel_rd_valid;
            lineBuffer_rd_valid[0] = pixel_rd_valid;
            lineBuffer_rd_valid[1] = 1'b0;
        end
        3:begin
            lineBuffer_rd_valid[3] = pixel_rd_valid;
            lineBuffer_rd_valid[0] = pixel_rd_valid;
            lineBuffer_rd_valid[1] = pixel_rd_valid;
            lineBuffer_rd_valid[2] = 1'b0;
        end
    endcase   
 end
 
 // ----------------------- MAQUINA DE ESTADOS PARA CONTROLAR LA LECTURA ----------------------- //
 always @(posedge i_clk)
 begin
    if(i_rst)
    begin
        readState <= IDLE;
        pixel_rd_valid <= 1'b0;
        o_interrupt <= 1'b0;
    end
    else
    begin
        case(readState) 
            IDLE:begin
                o_interrupt <= 1'b0;
                if(total_pixel >= 1536)
                begin
                    pixel_rd_valid <= 1'b1;
                    readState <= READ_ACTIVE;
                end
            end 
            READ_ACTIVE:begin //miramos si hemos leido 511 pixeles, si es asi tocaria leer el 512 y cambiamos de estado 
                if(pixel_rd_count == 511) // Esto ademas implica que hemos terminado con una fila, toca cambiar el contenido del linebuffer
                begin
                    readState <= IDLE;
                    pixel_rd_valid <= 1'b0;
                    o_interrupt <= 1'b1;
                end
            end
        endcase
    end
end  
 
 // -------------------- CONTADOR NUM TOTAL DE PIXELES EN LOS 4 LINEBUFFERS -------------------- //
 always @(posedge i_clk)
 begin
    if(i_rst)
        total_pixel <= 0;
    else
    begin
        if(i_pixel_valid & !pixel_rd_valid)
            total_pixel <= total_pixel + 1;
        else if(pixel_rd_valid & !i_pixel_valid)
            total_pixel <= total_pixel - 1;    
    end    
 end
 
 // ---------- Concatenamos los pixeles de salida para el modulo de operaciones conv.v ---------- //
 always @(*)
 begin
    case(read_buffer)
        0:begin
            o_pixel = {lineBuffer2_data, lineBuffer1_data, lineBuffer0_data};    
        end
        1:begin
            o_pixel = {lineBuffer3_data, lineBuffer2_data, lineBuffer1_data};
        end
        2:begin
            o_pixel = {lineBuffer0_data, lineBuffer3_data, lineBuffer2_data};
        end
        3:begin
            o_pixel = {lineBuffer1_data, lineBuffer0_data, lineBuffer3_data};
        end
    endcase   
 end
 
    
endmodule
