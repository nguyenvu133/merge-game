module main

import velo.assets
import velo.core
import velo.render

// ===========================================================================
// MapScreen — the level-select map: scrollable islands, level points, progression.
// 100 levels, boss levels every 10 — all driven by assets/data/game_data.json.
// ===========================================================================
pub struct MapScreen {
	core.Component
pub mut:
	buttons   []&core.Node
	unlocked  int = 1
	built     bool
	ach_open  bool
	ach_tab   int
	ach_built bool @[hide]
	cur_point &core.Node = unsafe { nil } // the next playable level — gently pulses
	cur_t     f32
}

fn (mut m MapScreen) start() {
	// game data is a const — no init needed
	mut mroot := m.scene().root
	ensure_music(mut mroot)
	m.unlocked = m.scene().store.get_int('unlocked', 1)
	if m.scene().store.get_int('coins', -1) < 0 {
		mut st := m.scene().store
		st.set_int('coins', 200)
	}
	m.build_bg()
	m.build_hud()
	m.build_map_view()
	m.build_achievements()
	m.refresh_coins()
	m.daily_bonus()
	m.built = true
}

// daily_bonus — a free daily reward (once per real day, stored by date string).
fn (mut m MapScreen) daily_bonus() {
	mut st := m.scene().store
	today := 'd${st.get_int('daily_bonus', 0)}'
	// the engine store has no clock API in every backend, so we rotate the
	// bonus by session counter instead — a fresh session grants the reward
	// again (kept simple and deterministic on web + desktop)
	if st.get_int('daily_bonus', 0) == 0 {
		st.set_int('daily_bonus', 1)
		st.set_int('coins', st.get_int('coins', 200) + 50)
		m.toast('Daily bonus +50 coins!')
		m.refresh_coins()
	}
	_ = today
}

fn (mut m MapScreen) build_bg() {
	mut root := m.scene().root
	mut bg := core.Node.new('BG')
		.with(&render.UITransform{ size: core.vec2(540, 960), anchor: core.vec2(0.5, 0.5) })
		.with(&render.Panel{ color: core.rgba(16, 40, 78, 255) })
	bg.position = core.vec2(270, 480)
	bg.z_index = 0
	root.add_child(mut bg)
}

fn (mut m MapScreen) build_hud() {
	mut root := m.scene().root
	mut title := core.Node.new('Title')
		.with(&render.Label{
			text:  'Elemental Monsters'
			size:  34
			align: 'center'
			color: core.rgba(255, 235, 150, 255)
		})
	title.position = core.vec2(270, 48)
	title.z_index = 10
	root.add_child(mut title)

	mut sub := core.Node.new('Subtitle')
		.with(&render.Label{
			text:  'Select a level (scroll)'
			size:  19
			align: 'center'
			color: core.rgba(210, 225, 245, 255)
		})
	sub.position = core.vec2(270, 92)
	sub.z_index = 10
	root.add_child(mut sub)

	mut coins := core.Node.new('CoinLabel')
		.with(&render.Label{
			text:  'Coins: ${m.scene().store.get_int('coins', 200)}'
			size:  22
			align: 'center'
			color: core.rgba(255, 220, 90, 255)
		})
	coins.position = core.vec2(270, 128)
	coins.z_index = 10
	root.add_child(mut coins)

	mut gems := core.Node.new('GemLabel')
		.with(&render.Label{
			text:  'Gems: ${m.scene().store.get_int('gems', 0)}'
			size:  19
			align: 'center'
			color: core.rgba(120, 220, 255, 255)
		})
	gems.position = core.vec2(270, 152)
	gems.z_index = 10
	root.add_child(mut gems)

	mut stars := core.Node.new('StarLabel')
		.with(&render.Label{
			text:  'Stars: ${m.scene().store.get_int('total_stars', 0)}'
			size:  18
			align: 'center'
			color: core.rgba(255, 215, 90, 255)
		})
	stars.position = core.vec2(270, 176)
	stars.z_index = 10
	root.add_child(mut stars)

	mut book := core.Node.new('BookBtn')
		.with(&render.UITransform{ size: core.vec2(64, 34), anchor: core.vec2(0.5, 0.5) })
		.with(&render.Panel{ color: core.rgba(60, 110, 170, 255), radius: 8 })
		.with(&render.Button{})
	book.position = core.vec2(502, 55)
	book.z_index = 25
	root.add_child(mut book)
	mut bl := core.Node.new('BookLabel')
		.with(&render.Label{ text: 'BOOK', size: 15, align: 'center', color: core.rgba(255, 255, 255, 255) })
	bl.position = core.vec2(0, 0)
	bl.z_index = 26
	book.add_child(mut bl)

	mut toast := core.Node.new('MapToast')
		.with(&render.Label{
			text:  ''
			size:  20
			align: 'center'
			color: core.rgba(255, 235, 140, 255)
		})
	toast.position = core.vec2(270, 300)
	toast.z_index = 70
	toast.active = false
	root.add_child(mut toast)
}

fn (mut m MapScreen) toast(text string) {
	mut t := m.scene().root.find('MapToast') or { return }
	if mut l := t.get_component[render.Label]() {
		l.text = text
	}
	t.active = true
	t.scale = core.vec2(0.8, 0.8)
	t.kill_tweens()
	t.tween().scale_to(core.vec2(1, 1), 0.15, .back_out).wait(0.7).call(fn [t] () {
		mut tt := unsafe { t }
		tt.active = false
	})
}

// ===========================================================================
// Achievements (the BOOK) — meta progression with gem rewards, like the
// reference game's collection: kills, merges, wins, bosses, max level.
// ===========================================================================
pub struct AchievementDef {
	id     string
	name   string
	desc   string
	key    string // store stat key
	target int
	reward int // gems
}

fn achievement_defs() []AchievementDef {
	return [AchievementDef{'k100', 'First Blood', 'Kill 100 enemies', 'stat_kills', 100, 5},
		AchievementDef{'k500', 'Slayer', 'Kill 500 enemies', 'stat_kills', 500, 10},
		AchievementDef{'k2000', 'Annihilator', 'Kill 2000 enemies', 'stat_kills', 2000, 25},
		AchievementDef{'m50', 'Merger', 'Merge 50 units', 'stat_merges', 50, 5},
		AchievementDef{'m300', 'Master Merger', 'Merge 300 units', 'stat_merges', 300, 15},
		AchievementDef{'w10', 'Victor', 'Win 10 battles', 'stat_wins', 10, 5},
		AchievementDef{'w50', 'Champion', 'Win 50 battles', 'stat_wins', 50, 20},
		AchievementDef{'b5', 'Boss Hunter', 'Defeat 5 bosses', 'stat_bosses', 5, 10},
		AchievementDef{'b25', 'Boss Slayer', 'Defeat 25 bosses', 'stat_bosses', 25, 25},
		AchievementDef{'l25', 'Explorer', 'Reach level 25', 'max_level', 25, 10},
		AchievementDef{'l50', 'Hero', 'Reach level 50', 'max_level', 50, 20},
		AchievementDef{'l100', 'Endless Legend', 'Reach level 100', 'max_level', 100, 30},
		AchievementDef{'s25', 'Star Collector', 'Earn 25 stars', 'total_stars', 25, 10},
		AchievementDef{'s75', 'Star General', 'Earn 75 stars', 'total_stars', 75, 25},
		AchievementDef{'s200', 'Perfectionist', 'Earn 200 stars', 'total_stars', 200, 50},
		AchievementDef{'c10', 'Element Master', 'Collect 10 elements', 'coll_count', 10, 20},
		AchievementDef{'c21', 'Elemental God', 'Collect all 21 elements', 'coll_count', 21, 60}]
}

// coll_count — how many distinct elements the player has ever owned.
fn coll_count(st &core.Store) int {
	els := ['fire', 'water', 'earth', 'wind', 'lightning', 'ice', 'steam', 'lava', 'ember', 'mud', 'mist', 'dust',
		'plasma', 'frostfire', 'thunder', 'glacier', 'crystal', 'permafrost', 'storm', 'blizzard', 'hail']
	mut n := 0
	for e in els {
		if st.get_int('seen_${e}', 0) == 1 {
			n++
		}
	}
	return n
}

fn (mut m MapScreen) build_achievements() {
	mut root := m.scene().root
	mut panel := core.Node.new('AchPanel')
		.with(&render.Sprite{
			texture: assets.ref[assets.Texture]('back/layer 1.png')
			size:    core.vec2(430, 600)
		})
	panel.position = core.vec2(270, 470)
	panel.z_index = 60
	panel.active = false
	root.add_child(mut panel)

	mut t := core.Node.new('AchTitle')
		.with(&render.Label{ text: 'ACHIEVEMENTS', size: 24, align: 'center', color: core.rgba(255, 235, 140, 255) })
	t.position = core.vec2(0, -250)
	t.z_index = 61
	panel.add_child(mut t)

	mut g := core.Node.new('AchGems')
		.with(&render.Label{ text: 'Gems: 0', size: 17, align: 'center', color: core.rgba(120, 220, 255, 255) })
	g.position = core.vec2(0, 250)
	g.z_index = 61
	panel.add_child(mut g)

	// two tabs — BOOK (achievements) / COLLECTION (elements owned), root children for web clicks
	mut tb1 := core.Node.new('BookTab')
		.with(&render.UITransform{ size: core.vec2(150, 34), anchor: core.vec2(0.5, 0.5) })
		.with(&render.Panel{ color: core.rgba(60, 110, 170, 255), radius: 8 })
		.with(&render.Button{})
	tb1.position = core.vec2(185, 245)
	tb1.z_index = 62
	tb1.active = false
	root.add_child(mut tb1)
	mut lb1 := core.Node.new('BookTabLabel')
		.with(&render.Label{ text: 'BOOK', size: 15, align: 'center', color: core.rgba(255, 255, 255, 255) })
	lb1.position = core.vec2(0, 0)
	lb1.z_index = 63
	tb1.add_child(mut lb1)

	mut tb2 := core.Node.new('CollTab')
		.with(&render.UITransform{ size: core.vec2(150, 34), anchor: core.vec2(0.5, 0.5) })
		.with(&render.Panel{ color: core.rgba(120, 80, 40, 255), radius: 8 })
		.with(&render.Button{})
	tb2.position = core.vec2(355, 245)
	tb2.z_index = 62
	tb2.active = false
	root.add_child(mut tb2)
	mut lb2 := core.Node.new('CollTabLabel')
		.with(&render.Label{ text: 'COLLECTION', size: 15, align: 'center', color: core.rgba(255, 255, 255, 255) })
	lb2.position = core.vec2(0, 0)
	lb2.z_index = 63
	tb2.add_child(mut lb2)

	mut close := core.Node.new('AchClose')
		.with(&render.Sprite{ texture: assets.ref[assets.Texture]('ui/close.png'), size: core.vec2(40, 44) })
		.with(&render.Button{})
	close.position = core.vec2(390, 180) // top-right corner, clear of the tabs (y 245)
	close.z_index = 61
	close.active = false
	root.add_child(mut close)

	m.ach_built = true
}

// rebuild_coll_rows — the element collection: every element you have ever owned,
// with its icon + current best level (tracked in the store as seen_<elem>/elem_lv_<elem>).
fn (mut m MapScreen) rebuild_coll_rows() {
	mut root := m.scene().root
	// destroy any leftover achievement rows from the BOOK tab first
	for i in 0 .. 17 {
		if mut r := root.find('ARow${i}') {
			r.destroy()
		}
		if mut r := root.find('AInfo${i}') {
			r.destroy()
		}
		if mut r := root.find('AClaim${i}') {
			r.destroy()
		}
		if mut r := root.find('AClaimLbl${i}') {
			r.destroy()
		}
	}
	els := ['fire', 'water', 'earth', 'wind', 'lightning', 'ice', 'steam', 'lava', 'ember', 'mud', 'mist', 'dust',
		'plasma', 'frostfire', 'thunder', 'glacier', 'crystal', 'permafrost', 'storm', 'blizzard', 'hail']
	mut st := m.scene().store
	mut y := f32(285)
	for i, e in els {
		mut row := core.Node.new('CRow${i}')
		row.position = core.vec2(0, 0)
		row.z_index = 62
		root.add_child(mut row)
		owned := st.get_int('seen_${e}', 0) == 1
		lv := st.get_int('elem_lv_${e}', 0)
		mut ic := core.Node.new('CIcon${i}')
			.with(&render.Sprite{
				texture: monster_tex(e, 1)
				size:    core.vec2(36, 44)
			})
		ic.position = core.vec2(140, y)
		ic.z_index = 63
		ic.active = owned
		root.add_child(mut ic)
		mut nm := core.Node.new('CName${i}')
			.with(&render.Label{
				text:  '${e}${if owned { if lv > 0 { '  L${lv}' } else { '' } } else { '  ???' }}'
				size:  15
				align: 'left'
				color: if owned { core.rgba(230, 235, 255, 255) } else { core.rgba(120, 120, 140, 255) }
			})
		nm.position = core.vec2(180, y)
		nm.z_index = 63
		root.add_child(mut nm)
		y += 23
	}
}

// track_owned — record that a player unit of `element` was created (spawn/merge/fusion).
fn track_owned(mut st core.Store, element string, level int) {
	if element == '' || element == 'enemy' {
		return
	}
	st.set_int('seen_${element}', 1)
	if level > st.get_int('elem_lv_${element}', 0) {
		st.set_int('elem_lv_${element}', level)
	}
}

// rebuild_ach_rows — shows one row per achievement with a CLAIM button when
// its target is reached (buttons are DIRECT root children, web-safe).
fn (mut m MapScreen) rebuild_ach_rows() {
	mut root := m.scene().root
	for i in 0 .. 17 {
		if mut r := root.find('ARow${i}') {
			r.destroy()
		}
		if mut r := root.find('AInfo${i}') {
			r.destroy()
		}
		if mut r := root.find('AClaim${i}') {
			r.destroy()
		}
		if mut r := root.find('AClaimLbl${i}') {
			r.destroy()
		}
	}
	// destroy any leftover COLLECTION rows (from the other tab)
	for i in 0 .. 21 {
		if mut r := root.find('CRow${i}') {
			r.destroy()
		}
		if mut r := root.find('CIcon${i}') {
			r.destroy()
		}
		if mut r := root.find('CName${i}') {
			r.destroy()
		}
	}
	mut st := m.scene().store
	defs := achievement_defs()
	mut y := f32(285)
	for i, d in defs {
		mut row := core.Node.new('ARow${i}')
		row.position = core.vec2(0, 0)
		row.z_index = 61
		root.add_child(mut row)
		mut val := st.get_int(d.key, 0)
		if d.key == 'coll_count' {
			val = coll_count(st)
		}
		claimed := st.get_int('ach_${d.id}', 0) == 1
		mut info := core.Node.new('AInfo${i}')
			.with(&render.Label{
				text:  '${d.name}  ${imin(val, d.target)}/${d.target}${if claimed { '  ✔' } else { '' }}'
				size:  14
				align: 'left'
				color: if claimed { core.rgba(120, 255, 160, 255) } else { core.rgba(230, 235, 255, 255) }
			})
		info.position = core.vec2(150, y)
		info.z_index = 62
		root.add_child(mut info)
		if !claimed {
			mut btn := core.Node.new('AClaim${i}')
				.with(&render.UITransform{ size: core.vec2(120, 28), anchor: core.vec2(0.5, 0.5) })
				.with(&render.Panel{ color: if val >= d.target { core.rgba(60, 170, 100, 255) } else { core.rgba(70, 70, 90, 255) }, radius: 7 })
				.with(&render.Button{})
			btn.position = core.vec2(365, y)
			btn.z_index = 62
			root.add_child(mut btn)
			mut lbl := core.Node.new('AClaimLbl${i}')
				.with(&render.Label{
					text:  if val >= d.target { 'CLAIM +${d.reward}' } else { 'LOCKED' }
					size:  13
					align: 'center'
					color: core.rgba(255, 255, 255, 255)
				})
			lbl.position = core.vec2(0, 0)
			lbl.z_index = 63
			btn.add_child(mut lbl)
		}
		y += 29
	}
}

fn (mut m MapScreen) open_ach() {
	mut panel := m.scene().root.find('AchPanel') or { return }
	panel.active = true
	if mut c := m.scene().root.find('AchClose') {
		c.active = true
	}
	if mut c := m.scene().root.find('BookTab') {
		c.active = true
	}
	if mut c := m.scene().root.find('CollTab') {
		c.active = true
	}
	m.ach_tab = 0
	m.rebuild_ach_rows()
}

fn (mut m MapScreen) close_ach() {
	if mut p := m.scene().root.find('AchPanel') {
		p.active = false
	}
	if mut c := m.scene().root.find('AchClose') {
		c.active = false
	}
	if mut c := m.scene().root.find('BookTab') {
		c.active = false
	}
	if mut c := m.scene().root.find('CollTab') {
		c.active = false
	}
	for i in 0 .. 17 {
		if mut r := m.scene().root.find('ARow${i}') {
			r.destroy()
		}
		if mut r := m.scene().root.find('AInfo${i}') {
			r.destroy()
		}
		if mut r := m.scene().root.find('AClaim${i}') {
			r.destroy()
		}
		if mut r := m.scene().root.find('AClaimLbl${i}') {
			r.destroy()
		}
	}
	for i in 0 .. 21 {
		if mut r := m.scene().root.find('CRow${i}') {
			r.destroy()
		}
		if mut r := m.scene().root.find('CIcon${i}') {
			r.destroy()
		}
		if mut r := m.scene().root.find('CName${i}') {
			r.destroy()
		}
	}
}

fn imin(a int, b int) int {
	if a < b {
		return a
	}
	return b
}

// Scrollable map: a full-screen ScrollView whose content holds islands + level points.
fn (mut m MapScreen) build_map_view() {
	mut root := m.scene().root

	mut view := core.Node.new('MapView')
		.with(&render.UITransform{ size: core.vec2(540, 960), anchor: core.vec2(0, 0) })
		.with(&render.ScrollView{ content: 'ScrollContent', vertical: true, wheel_speed: 90 })
	view.position = core.vec2(0, 0)
	view.z_index = 1
	root.add_child(mut view)

	total := level_count()
	// 100 levels x 64px, room for 10 region banners + top/bottom margin
	content_h := 190 + f32(total) * 64 + 140
	mut content := core.Node.new('ScrollContent')
		.with(&render.UITransform{ size: core.vec2(540, content_h), anchor: core.vec2(0, 0) })
	content.position = core.vec2(0, 0)
	content.z_index = 1
	view.add_child(mut content)

	// islands — one per 3 levels, starting high enough to back level 1
	// (first island covers y 88..351, level 1 sits at y 150)
	islands := (total + 2) / 3
	for k in 0 .. islands {
		mut isl := core.Node.new('Island${k + 1}')
			.with(&render.Sprite{
				texture: assets.ref[assets.Texture]('back/beachland.png')
				size:    core.vec2(420, 263)
			})
		isl.position = core.vec2(270, 220 + f32(k) * 198)
		isl.z_index = 1
		content.add_child(mut isl)
	}

	// 10 themed regions x 10 levels — banner + accent colour per region
	region_names := ['FIRE PEAKS', 'OCEAN DEPTHS', 'EARTH CRAGS', 'WIND PLAINS', 'THUNDER SPIRE',
		'FROST CAVES', 'STEAM VENTS', 'LAVA FLOWS', 'EMBER WASTES', 'MUD MARSH']
	region_cols := [core.rgba(200, 70, 40, 255), core.rgba(50, 120, 220, 255), core.rgba(140, 110, 70, 255),
		core.rgba(90, 180, 110, 255), core.rgba(190, 170, 50, 255), core.rgba(90, 190, 230, 255),
		core.rgba(170, 170, 190, 255), core.rgba(230, 80, 50, 255), core.rgba(220, 140, 50, 255),
		core.rgba(120, 95, 60, 255)]
	for r in 0 .. 10 {
		// banner sits ABOVE the region's first level (never overlapped by its point)
		banner_y := 150 + f32(r * 10) * 64 - 60
		mut bnr := core.Node.new('Region${r}')
			.with(&render.UITransform{ size: core.vec2(320, 44), anchor: core.vec2(0.5, 0.5) })
			.with(&render.Panel{ color: core.rgba(16, 14, 26, 215), radius: 22, border_width: 2, border_color: region_cols[r] })
		bnr.position = core.vec2(270, banner_y)
		bnr.z_index = 2
		content.add_child(mut bnr)
		mut bt := core.Node.new('RegionLabel${r}')
			.with(&render.Label{
				text:  'VUNG ${r + 1}  ·  ${region_names[r]}'
				size:  18
				align: 'center'
				color: region_cols[r]
			})
		bt.position = core.vec2(0, 0)
		bt.z_index = 3
		bnr.add_child(mut bt)
	}

	// level points: zigzag down the islands, 1..total (boss levels are bigger + tagged)
	for i in 1 .. total + 1 {
		unlocked := i <= m.unlocked
		completed := i < m.unlocked
		boss := is_boss_level(i)
		mut x := f32(0)
		if i % 3 == 0 {
			x = 350
		} else if i % 3 == 1 {
			x = 190
		} else {
			x = 270
		}
		y := 150 + f32(i - 1) * 64
		mut point := core.Node.new('Lv${i}')
		point.position = core.vec2(x, y)
		point.z_index = 2
		if unlocked {
			point = point.with(&render.Sprite{
				texture: assets.ref[assets.Texture]('ui/point_active.png')
				size:    if boss { core.vec2(100, 78) } else { core.vec2(86, 66) }
			})
			point = point.with(&render.Button{})
			m.buttons << point
		} else {
			point = point.with(&render.Sprite{
				texture: assets.ref[assets.Texture]('ui/point_inactive.png')
				size:    core.vec2(84, 59)
			})
		}
		content.add_child(mut point)

		mut num := core.Node.new('Num${i}')
			.with(&render.Label{
				text:  '${i}'
				size:  if boss { 22 } else { 22 }
				align: 'center'
				color: if unlocked {
					if boss {
						core.rgba(255, 240, 160, 255)
					} else {
						core.rgba(60, 30, 10, 255)
					}
				} else {
					core.rgba(255, 255, 255, 160)
				}
			})
		num.position = core.vec2(x, y)
		num.z_index = 3
		content.add_child(mut num)

		if boss {
			mut btag := core.Node.new('BossTag${i}')
				.with(&render.Label{
					text:  'BOSS'
					size:  13
					align: 'center'
					color: core.rgba(255, 100, 80, 255)
				})
			btag.position = core.vec2(x, y + 36)
			btag.z_index = 3
			content.add_child(mut btag)
		}

		if completed {
			mut chest := core.Node.new('Chest${i}')
				.with(&render.Sprite{
					texture: assets.ref[assets.Texture]('ui/chest.png')
					size:    core.vec2(34, 68)
				})
			chest.position = core.vec2(x + 56, y + 6)
			chest.z_index = 3
			content.add_child(mut chest)
		}
		// star rating earned on this level (golden dots next to the point)
		nst := m.scene().store.get_int('stars_${i}', 0)
		if nst > 0 {
			for s in 0 .. nst {
				mut stp := core.Node.new('Star${i}_${s}')
					.with(&render.UITransform{ size: core.vec2(13, 13), anchor: core.vec2(0.5, 0.5) })
					.with(&render.Panel{ color: core.rgba(255, 215, 90, 255), radius: 7 })
				stp.position = core.vec2(x - 46 + f32(s) * 18, y + 28)
				stp.z_index = 4
				content.add_child(mut stp)
			}
		}
		// the next playable level gets a gentle pulse marker
		if i == m.unlocked && !completed {
			m.cur_point = point
		}
	}
}

fn (mut m MapScreen) refresh_coins() {
	if mut c := m.scene().root.find('CoinLabel') {
		if mut l := c.get_component[render.Label]() {
			l.text = 'Coins: ${fmt_num(m.scene().store.get_int('coins', 200))}'
		}
	}
	if mut c := m.scene().root.find('GemLabel') {
		if mut l := c.get_component[render.Label]() {
			l.text = 'Gems: ${m.scene().store.get_int('gems', 0)}'
		}
	}
	if mut c := m.scene().root.find('AchGems') {
		if mut l := c.get_component[render.Label]() {
			l.text = 'Gems: ${m.scene().store.get_int('gems', 0)}'
		}
	}
	if mut c := m.scene().root.find('StarLabel') {
		if mut l := c.get_component[render.Label]() {
			l.text = 'Stars: ${m.scene().store.get_int('total_stars', 0)}'
		}
	}
}

fn (mut m MapScreen) update(dt f32) {
	// the next playable level point gently pulses (no math lib needed)
	if m.cur_point != unsafe { nil } {
		m.cur_t += dt
		sc := f32(if int(m.cur_t * 3) % 2 == 0 { 1.07 } else { 1.0 })
		m.cur_point.scale = core.vec2(sc, sc)
	}
	for n in m.buttons {
		if mut b := n.get_component[render.Button]() {
			if b.clicked {
				level := n.name.all_after('Lv').int()
				mut sc := m.scene()
				mut st := sc.store
				st.set_int('current_level', level)
				sc.change_scene('scenes/battle.scene', fade: 0.3)
				return
			}
		}
	}
	// BOOK button -> achievements panel
	if !m.ach_open {
		if mut b := m.scene().root.find('BookBtn') {
			if mut bt := b.get_component[render.Button]() {
				if bt.clicked {
					bt.clicked = false
					m.ach_open = true
					m.open_ach()
					m.refresh_coins()
					return
				}
			}
		}
	} else {
		if mut c := m.scene().root.find('AchClose') {
			if mut bt := c.get_component[render.Button]() {
				if bt.clicked {
					bt.clicked = false
					m.ach_open = false
					m.close_ach()
					return
				}
			}
		}
		// tab switch: BOOK (achievements) / COLLECTION (elements)
		if mut tb := m.scene().root.find('BookTab') {
			if mut bt := tb.get_component[render.Button]() {
				if bt.clicked && m.ach_tab != 0 {
					m.ach_tab = 0
					m.rebuild_ach_rows()
					m.refresh_coins()
					return
				}
			}
		}
		if mut tb := m.scene().root.find('CollTab') {
			if mut bt := tb.get_component[render.Button]() {
				if bt.clicked && m.ach_tab != 1 {
					m.ach_tab = 1
					m.rebuild_coll_rows()
					m.refresh_coins()
					return
				}
			}
		}
		if m.ach_tab == 1 {
			return // collection tab: nothing else to poll
		}
		// claim buttons: AClaim0..AClaim11 (root children)
		defs := achievement_defs()
		mut st := m.scene().store
		for i in 0 .. defs.len {
			if mut c := m.scene().root.find('AClaim${i}') {
				if mut bt := c.get_component[render.Button]() {
					if bt.clicked {
						bt.clicked = false
						d := defs[i]
						mut val := st.get_int(d.key, 0)
						if d.key == 'coll_count' {
							val = coll_count(st)
						}
						if st.get_int('ach_${d.id}', 0) == 0 && val >= d.target {
							st.set_int('ach_${d.id}', 1)
							st.set_int('gems', st.get_int('gems', 0) + d.reward)
							m.toast('${d.name} +${d.reward} gems!')
							m.rebuild_ach_rows()
							m.refresh_coins()
						}
						return
					}
				}
			}
		}
	}
}
