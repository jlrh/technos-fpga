/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-8-2024 */

module jtshadfrce_main(
    input                rst,
    input                clk,

    input                line_start,
    input         [ 8:0] vpos,

    output        [19:1] rom_addr,
    output reg           rom_cs,
    input                rom_ok,
    input         [15:0] rom_data,

    output        [14:1] vbus_addr,
    output        [15:0] vbus_dout,
    output        [ 1:0] vbus_we,
    output reg           vram_cs, fg_cs, spr_cs, pal_cs,
    input         [15:0] vram_q, fg_q, spr_q, pal_q,
    output               spr_hold,

    input                spr_copy_busy,
    input         [12:1] spr_copy_ptr,

    output reg    [ 8:0] scrx0, scry0, scrx1, scry1,
    output reg           flip,
    output reg           video_en,
    output reg    [ 7:0] brt,

    output reg           snd_on,
    output reg    [ 7:0] snd_latch,

    input         [ 9:0] joystick1,
    input         [ 9:0] joystick2,
    input         [ 1:0] cab_1p,
    input         [ 1:0] coin,
    input                service,
    input                dip_pause,
    input         [15:0] dipsw
);

wire [23:1] A;
wire        cpu_cen, cpu_cenb;
wire        UDSn, LDSn, RnW, ASn, VPAn, DTACKn, BUSn;
wire [ 2:0] FC;
reg  [ 2:0] IPLn;
wire [15:0] cpu_dout;
reg  [15:0] cpu_din;
reg         wram_cs, scr_cs, io_cs;
wire [15:0] wram_q;
reg  [15:0] io_dout;
wire [ 1:0] dsn_we;
wire        bus_cs, bus_busy;

assign rom_addr = A[19:1];
assign BUSn     = UDSn & LDSn;
assign VPAn     = !(!ASn && FC==3'd7);
assign dsn_we   = ~{UDSn, LDSn} & {2{~RnW}};

always @* begin
    rom_cs  = 0; vram_cs = 0; fg_cs = 0; spr_cs = 0; pal_cs = 0; wram_cs = 0; scr_cs = 0; io_cs = 0;
    if( !ASn && !BUSn ) begin
        case( A[23:16] )
            8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,
            8'h08,8'h09,8'h0A,8'h0B,8'h0C,8'h0D,8'h0E,8'h0F: rom_cs = 1;
            8'h10: vram_cs = A[15:14]==0;
            8'h14: begin fg_cs = A[15:13]==0; spr_cs = A[15:13]==1; end
            8'h18: pal_cs  = A[15]==0;
            8'h1C: scr_cs  = A[15:4]==0;
            8'h1D: io_cs   = A[15:6]==0;
            8'h1F: wram_cs = 1;
            default:;
        endcase
    end
end

assign spr_hold = spr_cs && !RnW && spr_copy_busy && A[12:1] >= spr_copy_ptr;
assign bus_cs   = rom_cs | spr_hold;
assign bus_busy = (rom_cs & ~rom_ok) | spr_hold;

assign vbus_addr = A[14:1];
assign vbus_dout = cpu_dout;
assign vbus_we   = dsn_we;

jtframe_ram16 #(.AW(15)) u_wram(
    .clk  ( clk ), .data( cpu_dout ), .addr( A[15:1] ), .we( dsn_we & {2{wram_cs}} ), .q( wram_q )
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        scrx0 <= 0; scry0 <= 0; scrx1 <= 0; scry1 <= 0; flip <= 0;
    end else if( scr_cs && !RnW && !LDSn ) begin
        case( A[3:1] )
            3'd0: scrx0 <= cpu_dout[8:0];
            3'd1: scry0 <= cpu_dout[8:0];
            3'd2: scrx1 <= cpu_dout[8:0];
            3'd3: scry1 <= cpu_dout[8:0];
            3'd5: flip  <= cpu_dout[0];
            default:;
        endcase
    end
end

reg  [2:0] irq;
reg        irqs_en, ras_en, vblank;
reg  [8:0] ras_sl;
reg  [3:0] prev_irqw;
reg        io_we_l;
wire       io_we = io_cs && !RnW;
wire       io_we_edge = io_we && !io_we_l;

always @* begin
    IPLn = irq[2] ? ~3'd3 : irq[1] ? ~3'd2 : irq[0] ? ~3'd1 : 3'b111;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        irq <= 0; irqs_en <= 0; ras_en <= 0; ras_sl <= 0; vblank <= 0; prev_irqw <= 0;
        video_en <= 0; brt <= 8'hff; snd_on <= 0; snd_latch <= 0; io_we_l <= 0;
    end else begin
        io_we_l <= io_we;
        snd_on  <= 0;

        if( line_start ) begin
            if( vpos==9'd0   ) vblank <= 0;
            if( vpos==9'd247 ) vblank <= 1;
            if( ras_en && vpos==ras_sl ) begin
                ras_sl <= ras_sl==9'd239 ? 9'd0 : ras_sl + 9'd1;
                irq[0] <= 1;
            end
            if( irqs_en && vpos[3:0]==0 ) irq[1] <= 1;
            if( irqs_en && vpos==9'd248 ) irq[2] <= 1;
        end
        if( io_we_edge ) begin
            case( A[5:1] )
                5'd0: irq[2] <= 0;
                5'd1: irq[1] <= 0;
                5'd2: irq[0] <= 0;
                5'd3: if( !LDSn ) begin
                    irqs_en  <= cpu_dout[0];
                    video_en <= cpu_dout[3];
                    if( !prev_irqw[2] &&  cpu_dout[2] ) ras_en <= 1;
                    if(  prev_irqw[2] && !cpu_dout[2] ) ras_en <= 0;
                    prev_irqw <= cpu_dout[3:0];
                end
                5'd4: if( !LDSn ) ras_sl <= cpu_dout[8:0];
                5'd6: begin
                    if( !UDSn ) begin snd_latch <= cpu_dout[15:8]; snd_on <= 1; end
                    if( !LDSn ) brt <= cpu_dout[7:0];
                end
                default:;
            endcase
        end
    end
end

wire [7:0] p1  = { cab_1p[0], joystick1[6:4], joystick1[3:0] };
wire [7:0] p2  = { cab_1p[1], joystick2[6:4], joystick2[3:0] };

wire [7:0] extra = { 2'b11, joystick2[9:7], joystick1[9:7] };
wire [3:0] sys = { 1'b1, service, coin[1], coin[0] };
wire [7:0] dsw1 = dipsw[7:0], dsw2 = dipsw[15:8];

always @(posedge clk) begin
    case( A[2:1] )
        2'd0: io_dout <= { 2'b0, dsw2[7:6], sys, p1 };
        2'd1: io_dout <= { 2'b0, dsw2[5:0], p2 };
        2'd2: io_dout <= { 2'b0, dsw1[5:0], extra };
        2'd3: io_dout <= { 2'b0, 3'b111, vblank, dsw1[7:6], 8'hff };
    endcase
end

always @(posedge clk) begin
    cpu_din <= rom_cs  ? rom_data :
               wram_cs ? wram_q   :
               vram_cs ? vram_q   :
               fg_cs   ? fg_q     :
               spr_cs  ? spr_q    :
               pal_cs  ? pal_q    :
               (io_cs && A[5]) ? io_dout : 16'h0;
end

jtframe_68kdtack_cen #(.W(6)) u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( 1'b0      ),
    .bus_ack    ( 1'b0      ),
    .ASn        ( ASn       ),
    .DSn        ({UDSn,LDSn}),
    .num        ( 5'd7      ),
    .den        ( 6'd24     ),
    .DTACKn     ( DTACKn    ),
    .wait2      ( 1'b0      ),
    .wait3      ( 1'b0      ),
    .fave       (           ),
    .fworst     (           )
);

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( rst         ),
    .RESETn     (             ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),
    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),
    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( VPAn        ),
    .FC         ( FC          ),
    .BERRn      ( 1'b1        ),
    .HALTn      ( dip_pause   ),
    .BRn        ( 1'b1        ),
    .BGACKn     ( 1'b1        ),
    .BGn        (             ),
    .DTACKn     ( DTACKn      ),
    .IPLn       ( IPLn        )
);

endmodule
