import type { Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import type { RenderSegment, SeparatorName, StatuslineConfig } from "./types.js";

export function renderClassicStatusline(
	width: number,
	segments: RenderSegment[],
	theme: Theme,
	config: StatuslineConfig,
): string {
	// One column of left margin. Kimi Code indents its whole UI by a column, and
	// pi's own message column is padded the same way (`outputPad`), so a
	// flush-left statusline was the one thing touching the terminal edge.
	return ` ${truncateToWidth(joinSegments(segments, theme, config), Math.max(0, width - 1), "")}`;
}

export function classicExtensionSeparator(theme: Theme): string {
	return theme.fg("dim", " · ");
}

function joinSegments(segments: RenderSegment[], theme: Theme, config: StatuslineConfig): string {
	const separator = separatorText(config.separator);
	return segments
		.map((segment, index) => styleSegment(segment, index, theme, config))
		.join(theme.fg("dim", separator));
}

function styleSegment(
	segment: RenderSegment,
	_index: number,
	theme: Theme,
	config: StatuslineConfig,
): string {
	const padding = config.density === "cozy" ? " " : "";
	const text = `${padding}${segment.text}${padding}`;
	const styledText = segment.emphasis ? theme.bold(text) : text;

	if (config.palette === "mono") {
		if (segment.color === "error" || segment.color === "warning") {
			return theme.fg(segment.color, styledText);
		}
		return theme.fg("muted", styledText);
	}

	return theme.fg(segment.color as ThemeColor, styledText);
}

function separatorText(separator: SeparatorName): string {
	switch (separator) {
		case "powerline":
			return "  ";
		case "bar":
			return " │ ";
		case "round":
			return " ❯ ";
		case "none":
			return " ";
		case "dot":
			return " · ";
	}
}
