import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const DISABLED_IN_PLAN = new Set(["edit", "write"]);
const PREFERRED_PLAN_TOOLS = ["read", "bash", "grep", "find", "ls", "subagent"];
const MUTATION_SUBAGENTS = new Set(["worker", "developer", "coder", "implementer", "develop", "executor", "delegate"]);

type Mode = "plan" | "build";

interface PersistedState {
	mode: Mode;
	toolsBeforePlanMode?: string[];
}

const DESTRUCTIVE_BASH_PATTERNS = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/(^|[^<])>(?!>)/,
	/>>/,
	/\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
	/\byarn\s+(add|remove|install|publish)/i,
	/\bpnpm\s+(add|remove|install|publish)/i,
	/\bpip\s+(install|uninstall)/i,
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|stash|cherry-pick|revert|tag|init|clone)/i,
	/\bsudo\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
	/\bkillall\b/i,
	/\b(vim?|nano|emacs|code|subl)\b/i,
];

const SAFE_BASH_PATTERNS = [
	/^\s*(cat|head|tail|less|more|grep|find|ls|pwd|echo|printf|wc|sort|uniq|diff|file|stat|du|df|tree|which|whereis|type|env|printenv|uname|whoami|id|date|uptime|ps|top|htop|free|jq|awk|rg|fd|bat|eza)\b/i,
	/^\s*sed\s+-n\b/i,
	/^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get|ls-)\b/i,
	/^\s*npm\s+(list|ls|view|info|search|outdated|audit)\b/i,
	/^\s*yarn\s+(list|info|why|audit)\b/i,
	/^\s*pnpm\s+(list|ls|view|info|search|outdated|audit)\b/i,
	/^\s*node\s+--version\b/i,
	/^\s*python\s+--version\b/i,
	/^\s*curl\s+/i,
	/^\s*wget\s+-O\s*-/i,
];

function isSafeBash(command: string): boolean {
	return SAFE_BASH_PATTERNS.some((pattern) => pattern.test(command)) &&
		!DESTRUCTIVE_BASH_PATTERNS.some((pattern) => pattern.test(command));
}

function uniqueKnownTools(pi: ExtensionAPI, names: string[]): string[] {
	const known = new Set(pi.getAllTools().map((tool) => tool.name));
	return [...new Set(names.filter((name) => known.has(name)))];
}

class PlanModeEditor extends CustomEditor {
	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		keybindings: ConstructorParameters<typeof CustomEditor>[2],
		private readonly getMode: () => Mode,
		private readonly toggleMode: () => void,
	) {
		super(tui, theme, keybindings);
	}

	private isAtEmptySpace(): boolean {
		const { line, col } = this.getCursor();
		const currentLine = this.getLines()[line] ?? "";
		if (col === 0) return true;
		return /\s/.test(currentLine[col - 1] ?? "");
	}

	handleInput(data: string): void {
		if (matchesKey(data, Key.tab)) {
			// Preserve pi's autocomplete UX for @file, /command, and path completions.
			// Use Tab for PLAN/BUILD only when the cursor is sitting on empty space.
			if (this.isShowingAutocomplete() || !this.isAtEmptySpace()) {
				super.handleInput(data);
				return;
			}
			this.toggleMode();
			return;
		}
		super.handleInput(data);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		const mode = this.getMode();
		const label = mode === "plan" ? " PLAN: Tab→build " : " BUILD: Tab→plan ";
		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= label.length) {
			lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
		}
		return lines;
	}
}

export default function planModeTab(pi: ExtensionAPI): void {
	let mode: Mode = "build";
	let toolsBeforePlanMode: string[] | undefined;

	pi.registerFlag("plan", {
		description: "Start in plan mode (read-only; Tab switches between PLAN and BUILD mode)",
		type: "boolean",
		default: false,
	});

	function persist(): void {
		pi.appendEntry("plan-mode-tab", { mode, toolsBeforePlanMode } satisfies PersistedState);
	}

	function updateUi(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		if (mode === "plan") {
			ctx.ui.setStatus("plan-mode-tab", ctx.ui.theme.fg("warning", "🧭 PLAN"));
			ctx.ui.setWidget("plan-mode-tab", [
				ctx.ui.theme.fg("warning", "PLAN mode active") + ctx.ui.theme.fg("dim", " — write/edit disabled; bash is read-only. Press Tab for BUILD."),
			]);
		} else {
			ctx.ui.setStatus("plan-mode-tab", ctx.ui.theme.fg("success", "🔨 BUILD"));
			ctx.ui.setWidget("plan-mode-tab", undefined);
		}
	}

	function enterPlanMode(ctx: ExtensionContext, notify = true): void {
		if (mode === "plan") {
			updateUi(ctx);
			return;
		}
		mode = "plan";
		const previousTools = pi.getActiveTools();
		toolsBeforePlanMode = previousTools;

		const active = previousTools.filter((name) => !DISABLED_IN_PLAN.has(name));
		pi.setActiveTools(uniqueKnownTools(pi, [...active, ...PREFERRED_PLAN_TOOLS]));

		if (notify && ctx.hasUI) ctx.ui.notify("PLAN mode: edit/write disabled; bash restricted to read-only commands.", "info");
		updateUi(ctx);
		persist();
	}

	function enterBuildMode(ctx: ExtensionContext, notify = true): void {
		if (mode === "build") {
			updateUi(ctx);
			return;
		}
		mode = "build";
		pi.setActiveTools(uniqueKnownTools(pi, toolsBeforePlanMode ?? [...pi.getActiveTools(), "edit", "write"]));
		toolsBeforePlanMode = undefined;

		if (notify && ctx.hasUI) ctx.ui.notify("BUILD mode: normal tool access restored.", "info");
		updateUi(ctx);
		persist();
	}

	function toggle(ctx: ExtensionContext): void {
		if (mode === "plan") enterBuildMode(ctx);
		else enterPlanMode(ctx);
	}

	pi.registerCommand("plan", {
		description: "Switch to plan mode, or toggle with no args. Usage: /plan [on|off|build]",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (["off", "build", "false", "0"].includes(arg)) enterBuildMode(ctx);
			else if (["on", "plan", "true", "1"].includes(arg)) enterPlanMode(ctx);
			else toggle(ctx);
		},
	});

	pi.registerCommand("build", {
		description: "Switch to build mode (normal edit/write access)",
		handler: async (_args, ctx) => enterBuildMode(ctx),
	});

	pi.on("tool_call", async (event) => {
		if (mode !== "plan") return;

		if (DISABLED_IN_PLAN.has(event.toolName)) {
			return { block: true, reason: "PLAN mode: edit/write tools are disabled. Press Tab on an empty prompt or run /build to switch to BUILD mode." };
		}

		if (event.toolName === "bash") {
			const command = typeof event.input.command === "string" ? event.input.command : "";
			if (!isSafeBash(command)) {
				return { block: true, reason: `PLAN mode: bash command blocked because it is not read-only allowlisted. Switch to BUILD mode first if you want to run it.\nCommand: ${command}` };
			}
		}

		if (event.toolName === "subagent") {
			const agent = typeof event.input.agent === "string" ? event.input.agent : undefined;
			if (agent && MUTATION_SUBAGENTS.has(agent)) {
				return { block: true, reason: `PLAN mode: mutation-capable subagent '${agent}' is blocked. Use planner/oracle for planning, then switch to BUILD mode for executor/worker.` };
			}
		}
	});

	pi.on("before_agent_start", async () => {
		const content = mode === "plan"
			? `[PLAN MODE ACTIVE]\nYou are in read-only planning mode.\n\nRules:\n- Do not edit, write, create, delete, move, or modify files.\n- Use read-only inspection only.\n- Bash is restricted to safe read-only commands.\n- For substantial planning, prefer the planner subagent (or oracle for risky decisions).\n- Do not use executor/worker/developer/coder in PLAN mode.\n- Scout and reviewer are optional: use them only when you deem recon or review necessary, not automatically.\n- Produce a concrete numbered implementation plan and wait for the user to switch to BUILD mode before making changes.`
			: `[BUILD MODE ACTIVE]\nYou are in implementation mode.\n\nRules:\n- You may edit files directly when the task is straightforward.\n- For substantial approved plans or broad multi-file implementation, prefer the executor subagent (or worker) and supervise its result.\n- Planner/oracle are optional: use them only when planning/decision risk is high.\n- Scout and reviewer are optional: use them only when you deem recon or review necessary, not automatically.\n- Validate changes before summarizing when practical.`;
		return {
			message: {
				customType: "plan-mode-tab-context",
				display: false,
				content,
			},
		};
	});

	pi.on("context", async (event) => {
		return {
			messages: event.messages.filter((message) => {
				const maybeCustom = message as { customType?: string };
				return maybeCustom.customType !== "plan-mode-tab-context";
			}),
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		const lastEntry = ctx.sessionManager.getEntries()
			.filter((entry: { type: string; customType?: string }) => entry.type === "custom" && entry.customType === "plan-mode-tab")
			.pop() as { data?: PersistedState } | undefined;

		if (lastEntry?.data) {
			mode = lastEntry.data.mode ?? mode;
			toolsBeforePlanMode = lastEntry.data.toolsBeforePlanMode;
		}
		if (pi.getFlag("plan") === true) mode = "plan";

		if (ctx.mode === "tui") {
			ctx.ui.setEditorComponent((tui, theme, keybindings) =>
				new PlanModeEditor(tui, theme, keybindings, () => mode, () => toggle(ctx)),
			);
		}

		if (mode === "plan") {
			// Re-apply tool restrictions after startup/reload/resume.
			const active = (toolsBeforePlanMode ?? pi.getActiveTools()).filter((name) => !DISABLED_IN_PLAN.has(name));
			if (!toolsBeforePlanMode) toolsBeforePlanMode = pi.getActiveTools();
			pi.setActiveTools(uniqueKnownTools(pi, [...active, ...PREFERRED_PLAN_TOOLS]));
		}
		updateUi(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		if (mode === "plan") persist();
		if (ctx.hasUI) ctx.ui.setWidget("plan-mode-tab", undefined);
	});
}
