#!/usr/bin/env python3
"""
Data Validator for Public Health Records
Author: Oladokun Clement
Date: 2024
"""

import pandas as pd
import numpy as np
import re
from datetime import datetime, timedelta
import json
import sys
import os

class HealthDataValidator:
    """Comprehensive data validation for health surveillance records"""
    
    def __init__(self, input_file=None):
        self.data = None
        self.validation_report = {
            'total_records': 0,
            'valid_records': 0,
            'issues_found': [],
            'summary': {}
        }
        
        if input_file:
            self.load_data(input_file)
    
    def load_data(self, file_path):
        """Load data from CSV or Excel file"""
        try:
            if file_path.endswith('.csv'):
                self.data = pd.read_csv(file_path)
            elif file_path.endswith('.xlsx'):
                self.data = pd.read_csv(file_path)
            else:
                print(f"Unsupported file format: {file_path}")
                return False
            
            self.validation_report['total_records'] = len(self.data)
            print(f"✅ Loaded {len(self.data)} records from {file_path}")
            return True
            
        except Exception as e:
            print(f"❌ Error loading file: {e}")
            return False
    
    def validate_dates(self):
        """Validate date fields for logical consistency"""
        issues = []
        
        if 'test_date' in self.data.columns:
            # Convert to datetime
            self.data['test_date'] = pd.to_datetime(self.data['test_date'], errors='coerce')
            
            # Check for future dates
            future_dates = self.data[self.data['test_date'] > datetime.now()]
            if len(future_dates) > 0:
                issues.append(f"Found {len(future_dates)} records with future test dates")
            
            # Check for dates too far in past (before 2000)
            old_dates = self.data[self.data['test_date'] < pd.Timestamp('2000-01-01')]
            if len(old_dates) > 0:
                issues.append(f"Found {len(old_dates)} records with test dates before 2000")
        
        if 'birth_date' in self.data.columns:
            self.data['birth_date'] = pd.to_datetime(self.data['birth_date'], errors='coerce')
            
            # Calculate age
            self.data['age'] = ((datetime.now() - self.data['birth_date']).dt.days / 365.25).astype(int)
            
            # Flag improbable ages
            improbable_ages = self.data[(self.data['age'] < 0) | (self.data['age'] > 110)]
            if len(improbable_ages) > 0:
                issues.append(f"Found {len(improbable_ages)} records with improbable ages (<0 or >110)")
        
        return issues
    
    def validate_numeric_ranges(self):
        """Validate numeric fields are within acceptable ranges"""
        issues = []
        
        numeric_checks = {
            'temperature': (35.0, 42.0),
            'blood_pressure_systolic': (70, 200),
            'blood_pressure_diastolic': (40, 130),
            'heart_rate': (40, 200),
            'weight_kg': (1.0, 200.0)
        }
        
        for field, (min_val, max_val) in numeric_checks.items():
            if field in self.data.columns:
                # Convert to numeric
                self.data[field] = pd.to_numeric(self.data[field], errors='coerce')
                
                # Find out of range values
                out_of_range = self.data[
                    (self.data[field] < min_val) | 
                    (self.data[field] > max_val)
                ]
                
                if len(out_of_range) > 0:
                    issues.append(f"Found {len(out_of_range)} records with {field} outside range ({min_val}-{max_val})")
        
        return issues
    
    def validate_required_fields(self):
        """Check that required fields are not empty"""
        issues = []
        
        required_fields = ['patient_id', 'test_date', 'facility_code']
        
        for field in required_fields:
            if field in self.data.columns:
                missing = self.data[field].isna().sum()
                if missing > 0:
                    issues.append(f"Found {missing} records missing required field: {field}")
        
        return issues
    
    def clean_phone_numbers(self):
        """Standardize phone number format"""
        if 'phone_number' in self.data.columns:
            # Remove all non-digit characters
            self.data['phone_number'] = self.data['phone_number'].astype(str).apply(
                lambda x: re.sub(r'\D', '', x)
            )
            
            # Validate length
            invalid_phones = self.data[
                ~self.data['phone_number'].str.match(r'^\d{10,15}$')
            ]
            
            if len(invalid_phones) > 0:
                return [f"Found {len(invalid_phones)} invalid phone numbers"]
        
        return []
    
    def remove_duplicates(self):
        """Remove duplicate records based on key fields"""
        duplicate_fields = ['patient_id', 'test_date']
        
        available_fields = [f for f in duplicate_fields if f in self.data.columns]
        
        if available_fields:
            duplicates = self.data.duplicated(subset=available_fields, keep='first')
            duplicate_count = duplicates.sum()
            
            if duplicate_count > 0:
                self.data = self.data[~duplicates]
                return [f"Removed {duplicate_count} duplicate records"]
        
        return []
    
    def generate_summary(self):
        """Generate validation summary"""
        if self.data is not None:
            self.validation_report['valid_records'] = len(self.data)
            completeness = (self.validation_report['valid_records'] / 
                          self.validation_report['total_records'] * 100)
            
            self.validation_report['summary'] = {
                'completeness_rate': round(completeness, 2),
                'cleaned_records': self.validation_report['valid_records'],
                'original_records': self.validation_report['total_records'],
                'issues_count': len(self.validation_report['issues_found'])
            }
    
    def run_full_validation(self):
        """Run all validation steps"""
        print("🔍 Starting comprehensive data validation...")
        
        all_issues = []
        
        # Run all validation methods
        all_issues.extend(self.remove_duplicates())
        all_issues.extend(self.validate_dates())
        all_issues.extend(self.validate_numeric_ranges())
        all_issues.extend(self.validate_required_fields())
        all_issues.extend(self.clean_phone_numbers())
        
        self.validation_report['issues_found'] = all_issues
        self.generate_summary()
        
        print(f"✅ Validation complete. Found {len(all_issues)} issues.")
        
        return all_issues
    
    def save_clean_data(self, output_file):
        """Save cleaned data to file"""
        if self.data is not None:
            if output_file.endswith('.csv'):
                self.data.to_csv(output_file, index=False)
            elif output_file.endswith('.xlsx'):
                self.data.to_excel(output_file, index=False)
            
            print(f"💾 Clean data saved to: {output_file}")
            return True
        return False
    
    def save_validation_report(self, report_file):
        """Save validation report to JSON file"""
        report_data = {
            'validation_timestamp': datetime.now().isoformat(),
            'validator_version': '1.0',
            'results': self.validation_report
        }
        
        with open(report_file, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"📊 Validation report saved to: {report_file}")


def main():
    """Main function for command-line usage"""
    print("=" * 60)
    print("HEALTH DATA VALIDATION TOOL")
    print("For ISAA Application - Oladokun Clement")
    print("=" * 60)
    
    # Create sample data if no file provided
    if len(sys.argv) < 2:
        print("\n⚠️  No input file provided. Creating sample data...")
        create_sample_data()
        input_file = 'sample_health_data.csv'
    else:
        input_file = sys.argv[1]
    
    # Initialize validator
    validator = HealthDataValidator(input_file)
    
    if validator.data is not None:
        # Run validation
        issues = validator.run_full_validation()
        
        # Save results
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        validator.save_clean_data(f'cleaned_data_{timestamp}.csv')
        validator.save_validation_report(f'validation_report_{timestamp}.json')
        
        # Print summary
        print("\n" + "=" * 60)
        print("VALIDATION SUMMARY")
        print("=" * 60)
        
        summary = validator.validation_report['summary']
        print(f"Total Records: {validator.validation_report['total_records']}")
        print(f"Valid Records: {summary['cleaned_records']}")
        print(f"Completeness Rate: {summary['completeness_rate']}%")
        print(f"Issues Found: {summary['issues_count']}")
        
        if issues:
            print("\n⚠️  Issues Found:")
            for issue in issues:
                print(f"  • {issue}")
        
        print("\n✅ Process completed successfully!")


def create_sample_data():
    """Create sample health data for demonstration"""
    sample_data = {
        'patient_id': ['P001', 'P002', 'P003', 'P004', 'P001', 'P005'],
        'patient_name': ['John Doe', 'Jane Smith', 'Bob Johnson', 'Alice Brown', 'John Doe', 'Charlie Wilson'],
        'test_date': ['2024-01-15', '2024-01-16', '2024-01-17', '2025-01-18', '2024-01-15', '2024-01-19'],
        'birth_date': ['1985-03-10', '1990-07-22', '1978-11-30', '2005-02-14', '1985-03-10', '1995-12-05'],
        'temperature': [36.5, 37.2, 35.8, 42.5, 36.5, 36.9],
        'phone_number': ['08012345678', '+2348012345679', 'invalid', '08123456789', '08012345678', '07012345678'],
        'facility_code': ['F001', 'F002', 'F001', None, 'F001', 'F003'],
        'test_result': ['Positive', 'Negative', 'Positive', 'Negative', 'Positive', 'Negative']
    }
    
    df = pd.DataFrame(sample_data)
    df.to_csv('sample_health_data.csv', index=False)
    print("📁 Created sample_health_data.csv with test data")


if __name__ == "__main__":
    main()