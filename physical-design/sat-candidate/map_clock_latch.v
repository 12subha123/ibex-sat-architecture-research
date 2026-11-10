(* techmap_celltype = "$dlatch" *)
module dlatch_map #(
    parameter WIDTH = 1,
    parameter EN_POLARITY = 0
) (
    input  [WIDTH-1:0] D,
    input  [WIDTH-1:0] EN,
    output [WIDTH-1:0] Q
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_latch
            if (EN_POLARITY == 0) begin: active_low
                DLL_X1 latch_cell (.D(D[i]), .GN(EN[i]), .Q(Q[i]));
            end else begin: active_high
                DLH_X1 latch_cell (.D(D[i]), .G(EN[i]), .Q(Q[i]));
            end
        end
    endgenerate
endmodule
