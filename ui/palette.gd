extends RefCounted
class_name Palette

## Tokens de cor centralizados (Fase 5, Parte A). Nada de cor mágica
## espalhada pela UI — tudo que aparece na tela vem daqui.
## Base escura e dessaturada (ferro/grafite); acentos saturados
## reservados para significado (estado), nunca decoração.

# --- base ---
const BG := Color("0a0b0d")
const PANEL := Color("14161a")
const PANEL_RAISED := Color("1b1e24")
const HAIRLINE := Color("2c3038")
const INK := Color("e8e6e0")
const INK_DIM := Color("9a9a9e")
const INK_FAINT := Color("5c5e64")

# --- acentos de significado (estado, não decoração) ---
const GOOD := Color("4caf6e")
const WARN := Color("d9a441")
const BAD := Color("c4453f")
const TRUTH_KNOWS := Color("c4453f")
const TRUTH_DOUBTS := Color("d9a441")
const TRUTH_CALM := Color("4caf6e")
const ISOLATED := Color("6b6d74")
const SELECTED := Color("f0ece0")

# --- tons-assinatura por estrato ---
const STRATUM_CROWN := Color("2a3a52")
const STRATUM_MEIOS := Color("233b2c")
const STRATUM_ENTRANHAS := Color("453322")
