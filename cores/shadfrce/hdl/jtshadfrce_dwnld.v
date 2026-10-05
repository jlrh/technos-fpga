module jtshadfrce_dwnld(
    input      [21:0] prog_addr,
    input      [ 1:0] prog_ba,
    output reg [21:0] post_addr
);

wire [18:0] w = prog_addr[18:0];

always @* begin
    post_addr = prog_addr;
    case( prog_ba )
        2'd1: if( prog_addr[21:20]==0 )
                post_addr = { 2'd0, prog_addr[18:0], prog_addr[19] };
        2'd2: if( prog_addr[21:19]==0 )
                post_addr = { 3'd0, w[18:5], w[3:0], w[4] };
        default:;
    endcase
end

endmodule
