import copy
import unittest
from scripts.summarize_pursuit_survey import validate_record,validate_contacts,validate_air


class PursuitSurveyReportTests(unittest.TestCase):
    def record(self):
        return dict(points=[[0,0],[64,0]],reachability=['11','11'],reachable_pairs=2,unreachable_pairs=0,
                    tested_pairs=[[0,1],[1,0]],physical_cases=2,unreachable_recovery_cases=0,
                    failures=[],recovery_failures=[],max_stationary_frames=22)

    def test_requires_actual_start_and_goal_coverage(self):
        record=self.record()
        self.assertEqual(validate_record(record),(2,2,0))
        record['tested_pairs']=[[0,1]]
        record['physical_cases']=1
        with self.assertRaises(ValueError):validate_record(record)

    def test_connectivity_counts_cannot_be_reported_as_physical_simulations(self):
        record=self.record()
        record['physical_cases']=200
        with self.assertRaises(ValueError):validate_record(record)

    def test_unreachable_points_require_recovery_evidence(self):
        record=self.record()
        record.update(reachability=['10','01'],reachable_pairs=0,unreachable_pairs=2,tested_pairs=[],physical_cases=0,unreachable_recovery_cases=2)
        self.assertEqual(validate_record(record),(2,0,2))
        record['unreachable_recovery_cases']=0
        with self.assertRaises(ValueError):validate_record(record)

    def test_failures_and_stationary_locks_are_rejected(self):
        for changes in [dict(failures=[{}]),dict(recovery_failures=[{}]),dict(max_stationary_frames=121)]:
            record=copy.deepcopy(self.record());record.update(changes)
            with self.assertRaises(ValueError):validate_record(record)

    def test_contacts_require_completed_physical_success(self):
        records=[dict(room='demo',kind='mono',cases=[dict(passed=True)],failures=[],skipped_overlapping_geometry=2,cold_build_frames=5)]
        self.assertEqual(validate_contacts(records,{('demo','mono')}),(1,2))
        records[0]['cases'][0]['passed']=False
        with self.assertRaises(ValueError):validate_contacts(records)
        records[0]['cases'][0]['passed']=True
        records[0]['cold_build_frames']=121
        with self.assertRaises(ValueError):validate_contacts(records)

    def test_contacts_cannot_omit_layout_or_enemy_type(self):
        records=[dict(room='demo',kind='mono',cases=[],failures=[],skipped_overlapping_geometry=0,cold_build_frames=5)]
        with self.assertRaises(ValueError):validate_contacts(records,{('demo','mono'),('demo','tian')})

    def test_air_requires_all_layouts_and_dynamic_checks(self):
        data=dict(records=[dict(room='demo',free_cells=10,passed=True,cases=[dict(arrived=True,physical=True,max_stationary=12)])],dynamic_checks=6,failures=0)
        self.assertEqual(validate_air(data,{'demo'}),(1,6))
        with self.assertRaises(ValueError):validate_air(data,{'demo','other'})
        data['dynamic_checks']=0
        with self.assertRaises(ValueError):validate_air(data,{'demo'})

    def test_air_cannot_hide_failed_traversal_or_physics(self):
        for field,value in [('arrived',False),('physical',False),('max_stationary',121)]:
            case=dict(arrived=True,physical=True,max_stationary=0)
            case[field]=value
            data=dict(records=[dict(room='demo',free_cells=10,passed=True,cases=[case])],dynamic_checks=6,failures=0)
            with self.assertRaises(ValueError):validate_air(data,{'demo'})
