.pragma library

// Central theme definitions for notchD.
// Edit these values or add a new theme object here. Theme names are keys.
var themes = {
    gruvbox: {
        name: "gruvbox",
        label: "Gruvbox Dark",
        bg: "#282828",
        elevated: "#3c3836",
        fg: "#ebdbb2",
        muted: "#a89984",
        accent: "#fabd2f",
        accentDim: "#d79921",
        border: "#504945",
        green: "#b8bb26",
        red: "#fb4934",
        blue: "#83a598",
        purple: "#d3869b",
        aqua: "#8ec07c",
        shadow: "#000000",
        hairline: "#504945"
    },

    eink: {
        name: "eink",
        label: "E-Ink Paper",
        bg: "#f4f4ef",
        elevated: "#ffffff",
        fg: "#171717",
        muted: "#6b6b6b",
        accent: "#171717",
        accentDim: "#3a3a3a",
        border: "#d4d4cf",
        green: "#2f6f4e",
        red: "#a33a3a",
        blue: "#3a5a7a",
        purple: "#6a4a7a",
        aqua: "#3f7a72",
        shadow: "#000000",
        hairline: "#d4d4cf"
    },

    vercel: {
        name: "vercel",
        label: "Vercel Inverse",
        bg: "#0a0a0a",
        elevated: "#141414",
        fg: "#ededed",
        muted: "#8f8f8f",
        accent: "#ffffff",
        accentDim: "#5e6ad2",
        border: "#2a2a2a",
        green: "#23e69b",
        red: "#ff6b6b",
        blue: "#5e6ad2",
        purple: "#5e6ad2",
        aqua: "#8ec07c",
        shadow: "#000000",
        hairline: "#2a2a2a"
    }
};

function has(name) {
    return Object.prototype.hasOwnProperty.call(themes, name);
}

function resolve(name) {
    return has(name) ? themes[name] : themes.gruvbox;
}

function names() {
    return ["gruvbox", "eink", "vercel"];
}
