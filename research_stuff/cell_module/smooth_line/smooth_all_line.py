from cell_module.smooth_line.smooth_horizontal_lines import smooth_line_horizontal
from cell_module.smooth_line.smooth_vetical_lines import smooth_line_vertical


def smooth_line(line_matrix, horizontal=True, test=False):
	if horizontal:
		return smooth_line_horizontal(line_matrix, test)
	return smooth_line_vertical(line_matrix, test)
