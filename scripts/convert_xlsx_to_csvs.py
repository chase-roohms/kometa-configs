#!/usr/bin/env python3
"""
Convert Excel (.xlsx) file sheets to individual CSV files.

This script reads an Excel file and exports each sheet as a separate CSV file,
using the sheet name as the filename.
"""

import argparse
import sys
from pathlib import Path
import pandas as pd


def convert_xlsx_to_csvs(input_file: str, output_dir: str) -> None:
    """
    Convert each sheet in an Excel file to a separate CSV file.
    
    Args:
        input_file: Path to the input .xlsx file
        output_dir: Directory where CSV files will be saved
    
    Raises:
        FileNotFoundError: If input file doesn't exist
        ValueError: If input file is not an .xlsx file
    """
    input_path = Path(input_file)
    output_path = Path(output_dir)
    
    # Validate input file
    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_file}")
    
    if input_path.suffix.lower() not in ['.xlsx', '.xls']:
        raise ValueError(f"Input file must be an Excel file (.xlsx or .xls): {input_file}")
    
    # Create output directory if it doesn't exist
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Read all sheets from the Excel file
    try:
        excel_file = pd.ExcelFile(input_path)
    except Exception as e:
        print(f"Error reading Excel file: {e}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(excel_file.sheet_names)} sheet(s) in {input_path.name}")
    
    # Convert each sheet to CSV
    for sheet_name in excel_file.sheet_names:
        # Read the sheet
        df = pd.read_excel(excel_file, sheet_name=sheet_name)
        
        # Create CSV filename (sanitize sheet name for filesystem)
        csv_filename = f"{sheet_name}.csv"
        csv_path = output_path / csv_filename
        
        # Save to CSV
        df.to_csv(csv_path, index=False)
        print(f"  ✓ Exported '{sheet_name}' to {csv_path}")
    
    print(f"\nSuccessfully converted {len(excel_file.sheet_names)} sheet(s) to CSV files in {output_path}")


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Convert Excel file sheets to individual CSV files"
    )
    parser.add_argument(
        "input",
        help="Path to the input Excel (.xlsx) file"
    )
    parser.add_argument(
        "output",
        help="Directory where CSV files will be saved"
    )
    
    args = parser.parse_args()
    
    try:
        convert_xlsx_to_csvs(args.input, args.output)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
