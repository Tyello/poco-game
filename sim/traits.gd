class_name Traits
extends RefCounted

## Pool de traços de personalidade (Fase 3). Puramente descritivo: rótulo
## legível para a UI e uma tag de "sabor" usada pelo gerador de
## micro-histórias (sim/story.gd). Nenhum efeito mecânico é aplicado por
## estes traços ainda — ver docs/09 ("Fora de escopo").

const POOL := [
	"cetico", "devoto", "leal", "resmungao",
	"curioso", "medroso", "tagarela", "reservado",
	"protetor", "sonhador", "pragmatico", "orgulhoso",
]

const LABELS := {
	"cetico": "cética",
	"devoto": "devota",
	"leal": "leal",
	"resmungao": "resmungona",
	"curioso": "curiosa",
	"medroso": "medrosa",
	"tagarela": "tagarela",
	"reservado": "reservada",
	"protetor": "protetora",
	"sonhador": "sonhadora",
	"pragmatico": "pragmática",
	"orgulhoso": "orgulhosa",
}

static func label(trait_id: String) -> String:
	return LABELS.get(trait_id, trait_id)

static func has(r: Resident, trait_id: String) -> bool:
	return trait_id in r.traits
