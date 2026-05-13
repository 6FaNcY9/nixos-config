{
  palette,
  c,
  yellowAlt,
  redAlt,
  elementBg,
  surface,
}:
''
  * {
      bg-col:              ${palette.bg};
      bg-col-light:        ${palette.bgAlt};
      border-col:          ${palette.muted};
      selected-col:        ${c.base0F};
      orange:              ${c.base0F};
      orange-alt:          ${palette.orange};
      yellow:              ${palette.warn};
      yellow-alt:          ${yellowAlt};
      fg-col:              ${palette.text};
      fg-col2:             ${c.base06};
      grey:                ${palette.muted};
      cream:               ${palette.cream};
      red-alt:             ${redAlt};
      element-bg:          ${elementBg};
      element-alternate-bg:${palette.bg};
      highlight:           underline bold ${yellowAlt};

      accent-green:        ${palette.accent};
      accent-blue:         ${palette.accent2};
      purple:              ${palette.purple};
      surface:             ${surface};
      green:               ${palette.aqua};
  }
''
