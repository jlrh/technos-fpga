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

module jtshadfrce_game(
    `include "jtframe_game_ports.inc"
);

wire [14:1] vbus_addr;
wire [15:0] vbus_dout, vram_q, fg_q, spr_q, pal_q;
wire [ 1:0] vbus_we;
wire        vram_cs, fg_cs, spr_cs, pal_cs, spr_hold;
wire        spr_copy_busy;
wire [12:1] spr_copy_ptr;
wire [ 8:0] scrx0, scry0, scrx1, scry1, vpos;
wire        flip, video_en, line_start, snd_on;
wire [ 7:0] brt, snd_latch;
wire [ 1:0] pxl_cens;

assign dip_flip   = flip;
assign debug_view = 8'd0;
assign pxl2_cen   = pxl_cens[0];
assign pxl_cen    = pxl_cens[1];
`ifndef JTFRAME_RELEASE
assign ioctl_din  = 8'd0;
`endif

jtframe_frac_cen #(.W(2),.WC(6)) u_pxlcen(
    .clk    ( clk       ),
    .n      ( 6'd14     ),
    .m      ( 6'd48     ),
    .cen    ( pxl_cens  ),
    .cenb   (           )
);

wire [21:0] dw_addr;
jtshadfrce_dwnld u_dwnld(
    .prog_addr  ( prog_addr[21:0] ),
    .prog_ba    ( prog_ba         ),
    .post_addr  ( dw_addr         )
);
always @* post_addr = dw_addr;

/* verilator tracing_off */
jtshadfrce_main u_main(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .line_start ( line_start    ),
    .vpos       ( vpos          ),

    .rom_addr   ( main_addr     ),
    .rom_cs     ( main_cs       ),
    .rom_ok     ( main_ok       ),
    .rom_data   ( main_data     ),

    .vbus_addr  ( vbus_addr     ),
    .vbus_dout  ( vbus_dout     ),
    .vbus_we    ( vbus_we       ),
    .vram_cs    ( vram_cs       ),
    .fg_cs      ( fg_cs         ),
    .spr_cs     ( spr_cs        ),
    .pal_cs     ( pal_cs        ),
    .vram_q     ( vram_q        ),
    .fg_q       ( fg_q          ),
    .spr_q      ( spr_q         ),
    .pal_q      ( pal_q         ),
    .spr_hold   ( spr_hold      ),
    .spr_copy_busy( spr_copy_busy ),
    .spr_copy_ptr ( spr_copy_ptr  ),

    .scrx0      ( scrx0         ),
    .scry0      ( scry0         ),
    .scrx1      ( scrx1         ),
    .scry1      ( scry1         ),
    .flip       ( flip          ),
    .video_en   ( video_en      ),
    .brt        ( brt           ),

    .snd_on     ( snd_on        ),
    .snd_latch  ( snd_latch     ),

    .joystick1  ( joystick1[6:0]),
    .joystick2  ( joystick2[6:0]),
    .cab_1p     ( cab_1p[1:0]   ),
    .coin       ( coin[1:0]     ),
    .service    ( service       ),
    .dip_pause  ( dip_pause     ),
    .dipsw      ( dipsw[15:0]   )
);
/* verilator tracing_on */
jtshadfrce_video u_video(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),

    .line_start ( line_start    ),
    .vpos       ( vpos          ),

    .vbus_addr  ( vbus_addr     ),
    .vbus_dout  ( vbus_dout     ),
    .vbus_we    ( vbus_we       ),
    .vram_cs    ( vram_cs       ),
    .fg_cs      ( fg_cs         ),
    .spr_cs     ( spr_cs        ),
    .pal_cs     ( pal_cs        ),
    .spr_hold   ( spr_hold      ),
    .vram_q     ( vram_q        ),
    .fg_q       ( fg_q          ),
    .spr_q      ( spr_q         ),
    .pal_q      ( pal_q         ),
    .spr_copy_busy( spr_copy_busy ),
    .spr_copy_ptr ( spr_copy_ptr  ),

    .scrx0      ( scrx0         ),
    .scry0      ( scry0         ),
    .scrx1      ( scrx1         ),
    .scry1      ( scry1         ),
    .video_en   ( video_en      ),
    .brt        ( brt           ),

    .scr_addr   ( scr_addr      ),
    .scr_cs     ( scr_cs        ),
    .scr_ok     ( scr_ok        ),
    .scr_data   ( scr_data      ),
    .scr2_addr  ( scr2_addr     ),
    .scr2_cs    ( scr2_cs       ),
    .scr2_ok    ( scr2_ok       ),
    .scr2_data  ( scr2_data     ),
    .obj_addr   ( obj_addr      ),
    .obj_cs     ( obj_cs        ),
    .obj_ok     ( obj_ok        ),
    .obj_data   ( obj_data      ),
    .obj4_addr  ( obj4_addr     ),
    .obj4_cs    ( obj4_cs       ),
    .obj4_ok    ( obj4_ok       ),
    .obj4_data  ( obj4_data     ),
    .fgrom_addr ( fgrom_addr    ),
    .fgrom_data ( fgrom_data    ),

    .LHBL       ( LHBL          ),
    .LVBL       ( LVBL          ),
    .HS         ( HS            ),
    .VS         ( VS            ),
    .red        ( red           ),
    .green      ( green         ),
    .blue       ( blue          ),
    .gfx_en     ( gfx_en        ),
    .busy       (               )
);
/* verilator tracing_off */
jtshadfrce_sound u_sound(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .cen_fm     ( cen_fm    ),
    .cen_fm2    ( cen_fm2   ),
    .cen_oki    ( cen_oki   ),

    .snd_on     ( snd_on    ),
    .snd_latch  ( snd_latch ),

    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),

    .pcm_addr   ( pcm_addr  ),
    .pcm_cs     ( pcm_cs    ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    .fm_l       ( fm_l      ),
    .fm_r       ( fm_r      ),
    .pcm        ( pcm       )
);

endmodule
