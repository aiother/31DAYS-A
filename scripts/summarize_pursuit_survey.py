"""Validate and publish the finite all-Room pursuit coverage evidence."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'outputs'


def validate_record(record):
    n = len(record['points'])
    rows = record['reachability']
    if not n or len(rows) != n or any(len(row) != n or set(row)-{'0', '1'} for row in rows):
        raise ValueError('invalid reachability matrix')
    if any(rows[i][i] != '1' for i in range(n)):
        raise ValueError('point must reach itself')
    reachable = sum(row.count('1')-1 for row in rows)
    if reachable != record['reachable_pairs'] or n*(n-1)-reachable != record['unreachable_pairs']:
        raise ValueError('ordered pair counts disagree with evidence')
    pairs = [tuple(pair) for pair in record['tested_pairs']]
    if len(set(pairs)) != len(pairs) or len(pairs) != record['physical_cases']:
        raise ValueError('physical cases must be unique and counted exactly')
    for a, b in pairs:
        if a == b or not (0 <= a < n and 0 <= b < n) or rows[a][b] != '1':
            raise ValueError('physical route must have a supported path')
    sources, goals = {a for a, _ in pairs}, {b for _, b in pairs}
    for i in range(n):
        if rows[i].count('1') > 1 and i not in sources:
            raise ValueError('missing physical starting-point coverage')
        if any(rows[a][i] == '1' for a in range(n) if a != i) and i not in goals:
            raise ValueError('missing physical destination-point coverage')
    recovery_cases = sum('0' in row for row in rows)
    if recovery_cases != record['unreachable_recovery_cases']:
        raise ValueError('unreachable starts must each have recovery coverage')
    if record['failures'] or record['recovery_failures'] or record['max_stationary_frames'] > 120:
        raise ValueError('survey contains a physical or recovery failure')
    return n, len(pairs), recovery_cases


def validate_contacts(records, expected=None):
    identities={(r['room'],r['kind']) for r in records}
    if len(identities)!=len(records) or (expected is not None and identities!=expected):
        raise ValueError('missing or duplicated contact layout coverage')
    count=skipped=0
    for record in records:
        if not 0<record['cold_build_frames']<=120:
            raise ValueError('cold-start graph exceeded bounded planning window')
        if record['failures'] or any(not c['passed'] for c in record['cases']):
            raise ValueError('contact perturbation failed to regain safe support')
        count+=len(record['cases'])
        skipped+=record['skipped_overlapping_geometry']
    return count,skipped


def validate_air(data, layouts):
    records=data['records']
    if len(records)!=len(layouts) or {r['room'] for r in records}!=layouts:
        raise ValueError('missing or duplicated flying layout coverage')
    if data['failures'] or data['dynamic_checks']<6:
        raise ValueError('missing successful flying dynamic recovery checks')
    count=0
    for record in records:
        if not record['passed'] or not record['cases'] or record['free_cells']<=0:
            raise ValueError('flying layout has no completed physical evidence')
        for case in record['cases']:
            if not case['arrived'] or not case['physical'] or case['max_stationary']>120:
                raise ValueError('flying traversal failed or stalled')
            count+=1
    return count,data['dynamic_checks']


def main():
    records = []
    for shard in range(5):
        data = json.loads((OUT / f'pursuit_survey_{shard}.json').read_text(encoding='utf-8'))
        if data['shard'] != shard:
            raise ValueError('wrong shard')
        count = 0
        for record in data['records']:
            _, physical, recoveries = validate_record(record)
            count += physical+recoveries
        if count != data['physical_simulations']:
            raise ValueError('simulation total disagrees with completed cases')
        records.extend(data['records'])
    identities = {(r['room'], r['kind']) for r in records}
    if len(records) != 48 or len(identities) != 48 or len({r['room'] for r in records}) != 24:
        raise ValueError('expected 18 Rooms and six additional geometry/gate phases, both enemy types')
    records.sort(key=lambda r: (r['room'], r['kind']))
    contacts=json.loads((OUT/'pursuit_contacts.json').read_text(encoding='utf-8'))['records']
    contact_cases,skipped_contacts=validate_contacts(contacts,identities)
    air=json.loads((OUT/'pursuit_air.json').read_text(encoding='utf-8'))
    air_cases,air_dynamic=validate_air(air,{r['room'] for r in records})
    totals = {
        'rooms': 18, 'geometry_layouts': 24, 'enemy_types': 2,
        'sampled_points_by_type': sum(len(r['points']) for r in records),
        'ordered_pairs': sum(r['reachable_pairs']+r['unreachable_pairs'] for r in records),
        'reachable_pairs': sum(r['reachable_pairs'] for r in records),
        'unreachable_pairs': sum(r['unreachable_pairs'] for r in records),
        'physical_routes': sum(r['physical_cases'] for r in records),
        'unreachable_recovery_cases': sum(r['unreachable_recovery_cases'] for r in records),
        'max_stationary_frames': max(r['max_stationary_frames'] for r in records),
        'failures': 0,
        'corner_contact_cases':contact_cases,
        'rejected_initial_overlaps':skipped_contacts,
        'max_cold_build_frames':max(r['cold_build_frames'] for r in contacts),
        'flying_physical_routes':air_cases,
        'flying_dynamic_checks':air_dynamic,
    }
    totals['physical_simulations'] = totals['physical_routes']+totals['unreachable_recovery_cases']+contact_cases+air_cases
    (OUT / 'pursuit_survey_summary.json').write_text(json.dumps(totals, indent=2), encoding='utf-8')
    with (OUT / 'pursuit_positions.csv').open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['layout', 'enemy', 'point', 'x', 'y', 'physical_source', 'physical_destination'])
        for record in records:
            sources = {a for a, _ in record['tested_pairs']}
            goals = {b for _, b in record['tested_pairs']}
            for index, (x, y) in enumerate(record['points']):
                writer.writerow([record['room'], record['kind'], index, x, y, index in sources, index in goals])
    with (OUT / 'pursuit_pairs.csv').open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['layout', 'enemy', 'start', 'goal', 'graph_reachable', 'physically_simulated_pair'])
        for record in records:
            tested = {tuple(pair) for pair in record['tested_pairs']}
            for a, row in enumerate(record['reachability']):
                for b, flag in enumerate(row):
                    if a != b:
                        writer.writerow([record['room'], record['kind'], a, b, flag == '1', (a, b) in tested])
    lines = [
        '# 高级追击AI全场景审计', '',
        '范围：18个已交付Room、Boss平台出现前后、最终战临时平台、围攻开门、堑壕返回/碎石堆开路和最终战胜利开门，共24种几何布局；单色地面实体和天人战士分别验证。', '',
        f"采样点（按敌种分别计）{totals['sampled_points_by_type']}；有向位置组合{totals['ordered_pairs']}；实际物理追击{totals['physical_routes']}次；不可达目标后恢复{totals['unreachable_recovery_cases']}次；角点接触扰动{contact_cases}次；失败0。", '',
        '采样包含每段可站立表面的两端、中心、64像素间隔，以及出入口、检查点、交互物和场景Node的横坐标投影。全部采样点有序组合进行有向路线检查；每个具有可达路径的点都作为起点和终点执行真实角色物理模拟，选取最远可达对应点，去除重复组合。每个存在不可达目标的起点，额外测试安全决策及目标回到可达位置后的恢复。', '',
        '这是有限坐标与布局的明确覆盖，不将路径图检查当成逐对物理实跑，也不声称穷尽连续坐标、所有输入时序或未来新增地图。可达案例必须实际进入目标所在表面并到达接敌距离或开始有效攻击；追击状态无进展超过120帧判失败，攻击前后摇和起跳冷却不计作僵直。', '',
        f"本轮可达案例最长追击无进展：{totals['max_stationary_frames']}个60Hz物理帧。动态专项另外覆盖视频位置、注入失效路线、空中不可达目标的远程压迫、目标返回地面、平台生成及配置变化。", '',
        f"首次构图另外按实际运行的每帧约1.8毫秒预算测试，48组布局/敌种组合均在120帧内完成，本轮最长{totals['max_cold_build_frames']}帧；该值受硬件性能影响。", '',
        '未连通表示在当前敌人体型、跳跃/下落限制和碰撞几何下，采样路线图未连接，不以穿墙、瞬移或无限跳高替代。敌人保留视线内远程压迫和安全搜索，持续重新决策；高墙、关闭的门或无落点断崖仍保留。', '',
        f'额外对每个表面两端采样胶囊圆角搭边接触，验证小跳重新落稳或安全下撤到合法地面后重选路线；{skipped_contacts}个初始姿态会与其他实体穿插而被拒绝，不冒充合法游戏位置。原始扰动位置、结果和排除数见pursuit_contacts.json。', '',
        f'飞行单色实体另行检查相同24种布局：{air_cases}次实际飞行绕障、{air_dynamic}项暂停/受击/目标恢复/几何改变检查。使用32像素全身体净空网格，抽取平台上下双向与可达极远位置；这组不计入地面采样点对矩阵，也不声称全部自由网格点对均已实跑。完整起终点与物理结果见pursuit_air.json。', '',
        '原始坐标见 pursuit_positions.csv；每对位置的规划/实跑区分见 pursuit_pairs.csv；完整矩阵和失败字段见 pursuit_survey_0.json 至 pursuit_survey_4.json。', '',
        '| 布局 | 敌种 | 点 | 有向组合 | 实跑追击 | 不可达恢复 |',
        '| --- | --- | ---: | ---: | ---: | ---: |',
    ]
    for r in records:
        label = '单色' if r['kind'] == 'monochrome_entity' else '天人'
        lines.append(f"| {r['room']} | {label} | {len(r['points'])} | {r['reachable_pairs']+r['unreachable_pairs']} | {r['physical_cases']} | {r['unreachable_recovery_cases']} |")
    (OUT / '追击AI全场景审计.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(json.dumps(totals, ensure_ascii=False))
    return totals


if __name__ == '__main__':
    main()
