module jtshadfrce_video #(parameter BG_START = 9'd160)(
    input                rst,
    input                clk,
    input                pxl_cen,

    output reg           line_start,
    output reg    [ 8:0] vpos,

    input         [14:1] vbus_addr,
    input         [15:0] vbus_dout,
    input         [ 1:0] vbus_we,
    input                vram_cs, fg_cs, spr_cs, pal_cs,
    input                spr_hold,
    output        [15:0] vram_q, fg_q, spr_q, pal_q,
    output reg           spr_copy_busy,
    output reg    [12:1] spr_copy_ptr,

    input         [ 8:0] scrx0, scry0, scrx1, scry1,
    input                video_en,
    input         [ 7:0] brt,

    output reg    [20:2] scr_addr,
    output reg           scr_cs,
    input                scr_ok,
    input         [31:0] scr_data,
    output reg    [19:2] scr2_addr,
    output reg           scr2_cs,
    input                scr2_ok,
    input         [31:0] scr2_data,

    output reg    [22:2] obj_addr,
    output reg           obj_cs,
    input                obj_ok,
    input         [31:0] obj_data,
    output reg    [20:1] obj4_addr,
    output reg           obj4_cs,
    input                obj4_ok,
    input         [15:0] obj4_data,

    output        [16:0] fgrom_addr,
    input         [ 7:0] fgrom_data,

    output reg           LHBL,
    output reg           LVBL,
    output reg           HS,
    output reg           VS,
    output reg    [ 7:0] red,
    output reg    [ 7:0] green,
    output reg    [ 7:0] blue,
    input         [ 3:0] gfx_en,

    output        [ 2:0] busy
);

reg  [8:0] hcnt = 0, vcnt = 0;
reg  [8:0] rline;
wire       rbank = rline[0];
wire       dbank = vcnt[0];

always @(posedge clk) begin
    line_start <= 0;
    if( pxl_cen ) begin
        if( hcnt==9'd447 ) begin
            hcnt <= 0;
            vcnt <= vcnt==9'd271 ? 9'd0 : vcnt+9'd1;
            line_start <= 1;
        end else hcnt <= hcnt + 9'd1;
    end
end

always @(posedge clk) begin
    vpos  <= vcnt;
    rline <= vcnt==9'd271 ? 9'd0 : vcnt + 9'd1;
end

wire [15:0] vram_vq, fg_vq, spr_vq, pal_vq;
reg  [13:1] vram_va;
reg  [12:1] fg_va;
reg  [12:1] spr_va;
reg  [14:1] pal_va;

jtframe_dual_ram16 #(.AW(13)) u_vram(
    .clk0 ( clk ), .data0( vbus_dout ), .addr0( vbus_addr[13:1] ), .we0( vbus_we & {2{vram_cs}} ), .q0( vram_q ),
    .clk1 ( clk ), .data1( 16'd0 ), .addr1( vram_va ), .we1( 2'b0 ), .q1( vram_vq )
);

jtframe_dual_ram16 #(.AW(12)) u_fgram(
    .clk0 ( clk ), .data0( vbus_dout ), .addr0( vbus_addr[12:1] ), .we0( vbus_we & {2{fg_cs}} ), .q0( fg_q ),
    .clk1 ( clk ), .data1( 16'd0 ), .addr1( fg_va ), .we1( 2'b0 ), .q1( fg_vq )
);

jtframe_dual_ram16 #(.AW(12)) u_sprram(
    .clk0 ( clk ), .data0( vbus_dout ), .addr0( vbus_addr[12:1] ), .we0( vbus_we & {2{spr_cs & ~spr_hold}} ), .q0( spr_q ),
    .clk1 ( clk ), .data1( 16'd0 ), .addr1( spr_va ), .we1( 2'b0 ), .q1( spr_vq )
);

jtframe_dual_ram16 #(.AW(14)) u_pal(
    .clk0 ( clk ), .data0( vbus_dout ), .addr0( vbus_addr[14:1] ), .we0( vbus_we & {2{pal_cs}} ), .q0( pal_q ),
    .clk1 ( clk ), .data1( 16'd0 ), .addr1( pal_va ), .we1( 2'b0 ), .q1( pal_vq )
);

reg  [9:0] fg_wa, bg_wa, ob_wa;
reg  [7:0] fg_wd;
reg  [10:0] bg_wd;
reg  [10:0] ob_wd;
reg        fg_we, bg1_we, bg0_we, ob_we;
wire [9:0] lb_ra = { dbank, hcnt };
wire [7:0] lfg;
wire [9:0] lbg1;
wire [10:0] lbg0, lobj;
reg        ob_clr;
wire       spr_busy;

jtframe_dual_ram #(.DW(8),.AW(10)) u_lbfg(
    .clk0( clk ), .data0( fg_wd ), .addr0( fg_wa ), .we0( fg_we ), .q0(),
    .clk1( clk ), .data1( 8'd0 ), .addr1( lb_ra ), .we1( 1'b0 ), .q1( lfg ) );
jtframe_dual_ram #(.DW(10),.AW(10)) u_lbbg1(
    .clk0( clk ), .data0( bg_wd[9:0] ), .addr0( bg_wa ), .we0( bg1_we ), .q0(),
    .clk1( clk ), .data1( 10'd0 ), .addr1( lb_ra ), .we1( 1'b0 ), .q1( lbg1 ) );
jtframe_dual_ram #(.DW(11),.AW(10)) u_lbbg0(
    .clk0( clk ), .data0( bg_wd ), .addr0( bg_wa ), .we0( bg0_we ), .q0(),
    .clk1( clk ), .data1( 11'd0 ), .addr1( lb_ra ), .we1( 1'b0 ), .q1( lbg0 ) );
jtframe_dual_ram #(.DW(11),.AW(10)) u_lbobj(
    .clk0( clk ), .data0( ob_wd ), .addr0( ob_wa ), .we0( ob_we ), .q0(),
    .clk1( clk ), .data1( 11'd0 ), .addr1( lb_ra ), .we1( ob_clr ), .q1( lobj ) );

localparam F_IDLE=0, F_W0=1, F_W1=2, F_R0=3, F_K=4, F_D=5, F_D2=6;
reg  [2:0]  fst;
reg  [5:0]  fc;
reg  [15:0] fw0;
reg  [11:0] fcode;
reg  [3:0]  fcol;
reg  [1:0]  fk;
reg  [7:0]  fbyte;
wire [4:0]  frow = rline[7:3];
wire [2:0]  fr   = rline[2:0];

assign fgrom_addr = { fcode, fk, fr };

always @* begin
    fg_va = { frow, fc, fst==F_W1 };
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        fst <= F_IDLE; fg_we <= 0;
    end else begin
        fg_we <= 0;
        case( fst )
            F_IDLE: if( line_start ) begin fc <= 0; fst <= F_W0; end
            F_W0: fst <= F_W1;
            F_W1: begin fw0 <= fg_vq; fst <= F_R0; end
            F_R0: begin
                fcode <= { fg_vq[3:0], fw0[7:0] };
                fcol  <= fg_vq[7:4];
                fk    <= 0;
                fst   <= F_K;
            end
            F_K: fst <= F_D;
            F_D: begin
                fbyte <= fgrom_data;
                fg_wa <= { rbank, fc, fk, 1'b0 };
                fg_wd <= { fcol, fgrom_data[6], fgrom_data[4], fgrom_data[2], fgrom_data[0] };
                fg_we <= 1;
                fst   <= F_D2;
            end
            F_D2: begin
                fg_wa <= { rbank, fc, fk, 1'b1 };
                fg_wd <= { fcol, fbyte[7], fbyte[5], fbyte[3], fbyte[1] };
                fg_we <= 1;
                if( fk==2'd3 ) begin
                    if( fc==6'd39 ) fst <= F_IDLE;
                    else begin fc <= fc + 6'd1; fst <= F_W0; end
                end else begin
                    fk  <= fk + 2'd1;
                    fst <= F_K;
                end
            end
            default: fst <= F_IDLE;
        endcase
    end
end

localparam B_IDLE=0, B_V0=1, B_V1=2, B_V2=3, B_RA=4, B_RW=5, B_RD=6, B_HAND=7;
reg  [2:0]  bst;
reg         blayer;
reg  [4:0]  bk;
reg  [8:0]  bsx0, bsy0, bsx1, bsy1;
reg  [15:0] bw0;
reg  [13:0] bcode;
reg  [4:0]  bcolr;
reg         bfx;
reg  [3:0]  brow;
reg  [1:0]  brd;
reg  [31:0] bd0, bd1, bd2;
reg  [1:0]  bwait;
wire [8:0]  bsx = blayer ? bsx1 : bsx0;
wire [8:0]  bsy = blayer ? bsy1 : bsy0;
wire [8:0]  by  = rline + bsy;
wire [4:0]  btc = bsx[8:4] + bk;

reg         dbusy, dlayer, dfx;
reg  [3:0]  di;
reg  [8:0]  dx0;
reg  [4:0]  dcol;
reg  [31:0] dd0, dd1, dd2;

always @* begin
    vram_va = blayer ? { 3'b100, by[8:4], btc } : { 2'b00, by[8:4], btc, bst==B_V1 };
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        bst <= B_IDLE; scr_cs <= 0; scr2_cs <= 0; dbusy <= 0; bg0_we <= 0; bg1_we <= 0;
    end else begin

        case( bst )
            B_IDLE: if( pxl_cen && hcnt==BG_START ) begin
                bsx0 <= scrx0; bsy0 <= scry0; bsx1 <= scrx1; bsy1 <= scry1;
                blayer <= 1; bk <= 0; bst <= B_V0;
            end
            B_V0: bst <= B_V1;
            B_V1: begin
                bw0 <= vram_vq;
                bst <= blayer ? B_RA : B_V2;
                if( blayer ) begin
                    bcode <= { 2'd0, vram_vq[11:0] };
                    bcolr <= { 1'b0, vram_vq[15:12] };
                    bfx   <= 0;
                    brow  <= by[3:0];
                end
            end
            B_V2: begin
                bcode <= vram_vq[13:0];
                bcolr <= bw0[4:0];
                bfx   <= bw0[6];
                brow  <= bw0[7] ? ~by[3:0] : by[3:0];
                bst   <= B_RA;
            end
            B_RA: begin
                scr_addr  <= { bcode, 1'b0, brow };
                scr2_addr <= { bcode, brow };
                scr_cs    <= 1;
                scr2_cs   <= 1;
                brd       <= 0;
                bwait     <= 2'd2;
                bst       <= B_RW;
            end
            B_RW: begin
                if( bwait!=0 ) bwait <= bwait - 2'd1;
                else begin
                    if( scr2_cs && scr2_ok ) begin bd2 <= scr2_data; scr2_cs <= 0; end
                    if( scr_cs && scr_ok ) begin
                        if( brd==0 ) begin
                            bd0      <= scr_data;
                            scr_addr <= { bcode, 1'b1, brow };
                            brd      <= 1;
                            bwait    <= 2'd2;
                        end else begin
                            bd1    <= scr_data;
                            scr_cs <= 0;
                        end
                    end
                    if( !scr_cs && !scr2_cs ) bst <= B_HAND;
                end
            end
            B_HAND: if( !dbusy ) begin

                dbusy  <= 1;
                dlayer <= blayer;
                dfx    <= bfx;
                di     <= 0;
                dx0    <= { bk, 4'd0 } - { 5'd0, bsx[3:0] };
                dcol   <= bcolr;
                dd0    <= bd0;
                dd1    <= bd1;
                dd2    <= bd2;
                if( bk==5'd20 ) begin
                    bk <= 0;
                    if( blayer ) begin blayer <= 0; bst <= B_V0; end
                    else bst <= B_IDLE;
                end else begin
                    bk  <= bk + 5'd1;
                    bst <= B_V0;
                end
            end
            default: bst <= B_IDLE;
        endcase

        bg0_we <= 0; bg1_we <= 0;
        if( dbusy ) begin : draw
            reg [3:0] sx;
            reg [2:0] j;
            reg       hh;
            reg [31:0] r01;
            reg [15:0] r2;
            reg [5:0] pen;
            sx  = dfx ? ~di : di;
            hh  = sx[3];
            j   = ~sx[2:0];
            r01 = hh ? dd1 : dd0;
            r2  = hh ? dd2[31:16] : dd2[15:0];
            pen = { r01[8+j], r01[j], r01[24+j], r01[16+j], r2[8+j], r2[j] };
            bg_wa <= { rbank, dx0 + {5'd0, di} };
            bg_wd <= { dcol, pen };
            if( dlayer ) bg1_we <= 1; else bg0_we <= 1;
            di <= di + 4'd1;
            if( di==4'd15 ) dbusy <= 0;
        end
    end
end

reg  [47:0] sbuf_wd;
reg  [8:0]  sbuf_wa;
reg         sbuf_we;
reg  [8:0]  sbuf_ra;
wire [47:0] sbuf_q;
reg  [39:0] cacc;
reg  [12:0] ccnt;
reg  [11:0] cidx;
reg         cvalid;

jtframe_dual_ram #(.DW(48),.AW(9)) u_sprbuf(
    .clk0( clk ), .data0( sbuf_wd ), .addr0( sbuf_wa ), .we0( sbuf_we ), .q0(),
    .clk1( clk ), .data1( 48'd0 ), .addr1( sbuf_ra ), .we1( 1'b0 ), .q1( sbuf_q ) );

always @* spr_va = ccnt[11:0];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        spr_copy_busy <= 0; spr_copy_ptr <= 0; ccnt <= 0; cidx <= 0; cvalid <= 0; sbuf_we <= 0;
    end else begin
        sbuf_we <= 0;
        if( !spr_copy_busy ) begin
            cvalid <= 0;
            if( line_start && vcnt==9'd248 ) begin
                spr_copy_busy <= 1;
                ccnt <= 0;
                spr_copy_ptr <= 0;
            end
        end else begin

            cvalid <= !ccnt[12];
            cidx   <= ccnt[11:0];
            if( !ccnt[12] ) ccnt <= ccnt + 13'd1;
            if( cvalid ) begin
                spr_copy_ptr <= cidx;
                case( cidx[2:0] )
                    3'd0: cacc[ 7: 0] <= spr_vq[7:0];
                    3'd1: cacc[15: 8] <= spr_vq[7:0];
                    3'd2: cacc[23:16] <= spr_vq[7:0];
                    3'd3: cacc[31:24] <= spr_vq[7:0];
                    3'd4: cacc[39:32] <= spr_vq[7:0];
                    3'd5: begin
                        sbuf_wa <= cidx[11:3];
                        sbuf_wd <= { spr_vq[7:0], cacc };
                        sbuf_we <= 1;
                    end
                    default:;
                endcase
                if( cidx==12'hfff ) spr_copy_busy <= 0;
            end
        end
    end
end

localparam OF_D = 8;
reg  [9:0]  sa;
reg         sev;
reg         scan_on;
reg  [35:0] ofifo [0:OF_D-1];
reg  [2:0]  ofr, ofw;
reg  [3:0]  ofn;

wire [7:0]  s0 = sbuf_q[ 7: 0], s1 = sbuf_q[15: 8], s2 = sbuf_q[23:16],
            s3 = sbuf_q[31:24], s4 = sbuf_q[39:32], s5 = sbuf_q[47:40];
wire        sen    = s0[2];
wire [10:0] sypos  = 11'd256 - { 1'b0, s0[1:0], s1 };
wire [10:0] sm     = sypos - { 2'd0, rline };
wire [10:0] sm2    = sm + 11'd512;
wire [7:0]  shgt   = { 1'b0, s0[7:5], 4'd0 } + 8'd16;
wire [10:0] sdm    = sm  - 11'd1;
wire [10:0] sdm2   = sm2 - 11'd1;
wire        shit1  = !sdm[10]  && sdm  < { 3'd0, shgt };
wire        shit2  = !sdm2[10] && sdm2 < { 3'd0, shgt };
wire        shit   = sen && (shit1 || shit2);
wire [6:0]  sdsel  = shit1 ? sdm[6:0] : sdm2[6:0];
wire [15:0] scode  = { s2, s3 } + { 13'd0, sdsel[6:4] };
wire [3:0]  srow   = s0[3] ? sdsel[3:0] : ~sdsel[3:0];
wire [8:0]  sx9    = { s4[0], s5 } + 9'd1;

wire [35:0] shitw  = { scode, srow, s0[4], s4[6], s4[5:1], sx9 };
wire        opush  = sev && shit;
reg         opop;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        scan_on <= 0; sev <= 0; sa <= 0; sbuf_ra <= 0; ofr <= 0; ofw <= 0; ofn <= 0;
    end else begin

        sev <= 0;
        if( line_start && !spr_copy_busy && vcnt!=9'd248 ) begin
            scan_on <= 1; sa <= 0; sbuf_ra <= 0;
        end else if( scan_on ) begin
            if( ofn < OF_D-2 ) begin
                if( sa==10'd512 ) scan_on <= 0;
                else begin
                    sev     <= 1;
                    sa      <= sa + 10'd1;
                    sbuf_ra <= sa[8:0] + 9'd1;
                end
            end
        end

        if( opush ) begin ofifo[ofw] <= shitw; ofw <= ofw + 3'd1; end
        if( opop  ) ofr <= ofr + 3'd1;
        ofn <= ofn + { 3'd0, opush } - { 3'd0, opop };
    end
end

localparam OC_IDLE=0, OC_RD=1, OC_RW=2, OC_HAND=3;
reg  [1:0]  ocst;
reg  [35:0] oent;
reg         ohalf;
reg  [1:0]  owait;
reg  [31:0] ocd;
reg  [7:0]  ocd4;

reg         odbusy, odfx, odpri, odhalf;
reg  [4:0]  odpal;
reg  [8:0]  odx;
reg  [31:0] odd;
reg  [7:0]  odd4;
reg  [2:0]  oi;

wire [15:0] e_code = oent[35:20];
wire [3:0]  e_row  = oent[19:16];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        ocst <= OC_IDLE; obj_cs <= 0; obj4_cs <= 0; opop <= 0; odbusy <= 0; ob_we <= 0;
    end else begin
        opop  <= 0;
        ob_we <= 0;
        case( ocst )
            OC_IDLE: if( ofn!=0 && !opop ) begin
                oent  <= ofifo[ofr];
                opop  <= 1;
                ohalf <= 0;
                ocst  <= OC_RD;
            end
            OC_RD: begin
                obj_addr  <= { e_code, ohalf, e_row };
                obj4_addr <= { e_code, ohalf, e_row[3:1] };
                obj_cs  <= 1;
                obj4_cs <= 1;
                owait   <= 2'd2;
                ocst    <= OC_RW;
            end
            OC_RW: begin
                if( owait!=0 ) owait <= owait - 2'd1;
                else if( obj_ok && obj4_ok ) begin
                    ocd  <= obj_data;
                    ocd4 <= e_row[0] ? obj4_data[15:8] : obj4_data[7:0];
                    obj_cs  <= 0;
                    obj4_cs <= 0;
                    ocst <= OC_HAND;
                end
            end
            OC_HAND: if( !odbusy ) begin
                odbusy <= 1;
                odd    <= ocd;
                odd4   <= ocd4;
                odfx   <= oent[15];
                odpri  <= oent[14];
                odpal  <= oent[13:9];
                odx    <= oent[8:0];
                odhalf <= ohalf;
                oi     <= 0;
                if( !ohalf ) begin ohalf <= 1; ocst <= OC_RD; end
                else ocst <= OC_IDLE;
            end
            default: ocst <= OC_IDLE;
        endcase

        if( odbusy ) begin : odraw
            reg [2:0] j;
            reg [4:0] pen;
            reg [3:0] px;
            j   = ~oi;
            pen = { odd[j], odd[8+j], odd[16+j], odd[24+j], odd4[j] };
            px  = { odhalf, oi };
            ob_wa <= { rbank, odx + { 5'd0, odfx ? ~px : px } };
            ob_wd <= { odpri, odpal, pen };
            ob_we <= pen != 5'd0;
            oi    <= oi + 3'd1;
            if( oi==3'd7 ) odbusy <= 0;
        end
    end
end

assign spr_busy = scan_on || sev || ofn!=0 || ocst!=OC_IDLE || odbusy;
assign busy     = { bst!=B_IDLE || dbusy, spr_busy, fst!=F_IDLE };

reg        cen_d1, mix_go, pal_go, pal_w, rgb_go;
reg [13:0] pidx;
reg        blank_px;
reg [8:0]  hcnt_d;
reg [8:0]  vcnt_d;
wire       op0  = lbg0[5:0] != 0;
wire       sopq = lobj[4:0] != 0;
wire [7:0] r8 = { pal_vq[ 4: 0], pal_vq[ 4: 2] };
wire [7:0] g8 = { pal_vq[ 9: 5], pal_vq[ 9: 7] };
wire [7:0] b8 = { pal_vq[14:10], pal_vq[14:12] };
wire [15:0] rm = r8 * brt, gm = g8 * brt, bm = b8 * brt;

function [7:0] div255(input [15:0] x);
    reg [16:0] t;
    begin
        t = { 1'b0, x } + { 9'd0, x[15:8] } + 17'd1;
        div255 = t[15:8];
    end
endfunction

always @(posedge clk) begin

    ob_clr <= 0;
    cen_d1 <= pxl_cen;
    mix_go <= cen_d1;
    pal_go <= mix_go;
    pal_w  <= pal_go;
    rgb_go <= pal_w;
    if( mix_go ) begin
        pidx <= { 2'b11, 2'b00, lbg1[9:6], lbg1[5:0] };
        if( op0 && gfx_en[1] )
            pidx <= { 2'b10, lbg0[10], 1'b0, lbg0[9:6], lbg0[5:0] };
        if( sopq && !(lobj[10] && op0) && gfx_en[3] )
            pidx <= { 2'b01, lobj[9], 1'b0, lobj[8:5], 1'b0, lobj[4:0] };
        if( lfg[3:0]!=0 && gfx_en[0] )
            pidx <= { 4'b0000, lfg[7:4], 2'b00, lfg[3:0] };
        ob_clr   <= 1;
        blank_px <= !video_en || !gfx_en[2];
    end
    if( pal_go ) pal_va <= pidx;
    if( rgb_go ) begin
        red   <= blank_px ? 8'd0 : div255( rm );
        green <= blank_px ? 8'd0 : div255( gm );
        blue  <= blank_px ? 8'd0 : div255( bm );
    end

    if( pxl_cen ) begin : sincro
        reg [8:0] hn, vn;
        hn = hcnt==9'd447 ? 9'd0 : hcnt + 9'd1;
        vn = hcnt==9'd447 ? (vcnt==9'd271 ? 9'd0 : vcnt + 9'd1) : vcnt;
        hcnt_d <= hn;
        vcnt_d <= vn;
        LHBL   <= hn < 9'd320;
        LVBL   <= vn >= 9'd8 && vn < 9'd248;
        HS     <= hn >= 9'd352 && hn < 9'd384;
        VS     <= vn >= 9'd252 && vn < 9'd255;
    end
end

endmodule
