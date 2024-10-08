#take input a local ancestry annotated VCF file (FLARE output) and outputs a BED file where consecutive SNPs with the same ancestry assignment merged. 
# python concatenate.ancestry.py <input.vcf> <output.bed>

import sys
import vcf

def vcf_to_bed(input_vcf, output_bed):
    vcf_reader = vcf.Reader(open(input_vcf, 'r'))
    bed_file = open(output_bed, 'w')
    
    current_region = None
    
    for record in vcf_reader:
        sample = record.samples[0]  # Assuming one sample per VCF
        an1, an2 = sample['AN1'], sample['AN2']
        
        if current_region is None:
            current_region = {
                'chrom': record.CHROM,
                'start': record.POS,
                'end': record.POS,
                'an1': an1,
                'an2': an2
            }
        elif an1 == current_region['an1'] and an2 == current_region['an2']:
            current_region['end'] = record.POS
        else:
            # Write the current region to the BED file
            bed_file.write("{}\t{}\t{}\t{}:{}\n".format(
                current_region['chrom'], current_region['start']-1, current_region['end'], current_region['an1'], current_region['an2']
            ))
            
            # Start a new region
            current_region = {
                'chrom': record.CHROM,
                'start': record.POS,
                'end': record.POS,
                'an1': an1,
                'an2': an2
            }
    
    # Write the last region
    if current_region:
        bed_file.write("{}\t{}\t{}\t{}:{}\n".format(
            current_region['chrom'], current_region['start']-1, current_region['end'], current_region['an1'], current_region['an2']
        ))
    
    bed_file.close()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python vcf_to_bed.py <input_vcf> <output_bed>")
        sys.exit(1)

    input_vcf = sys.argv[1]
    output_bed = sys.argv[2]
    
    vcf_to_bed(input_vcf, output_bed)
