module chipsel (
	output [7:0] o,
	input e0, input [7:0] d0,
	input e1, input [7:0] d1,
	input e2, input [7:0] d2,
	input [7:0] dx
);

	assign o = e0 ? d0 :
				e1 ? d1 :
				e2 ? d2 :
				dx;

endmodule
