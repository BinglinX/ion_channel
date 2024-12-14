import argparse
import multiprocessing
import subprocess
from Bio.PDB import PDBParser, Polypeptide
from Bio.Data.IUPACData import protein_letters_1to3 as one_to_three
import os


parser = argparse.ArgumentParser(description="Process some input arguments.")

parser.add_argument('-f', '--file', type=str, help='Path to the file')
parser.add_argument('-t', '--times', type=int, help='Times to run the self mutation')
parser.add_argument('-m', '--mut_path', type=str, help='Path to the mutation file')
parser.add_argument('-s', '--start', type=int, help='Start position of self mutation')
parser.add_argument('-e', '--end', type=int, help='End position of self mutation')

def parse_mutation(mut_path):
    #given the path to a mutation file, read the lines and return a dictionary of lists
    mut_list = []

    with open (mut_path) as mut_file:
        for line in mut_file.readlines():
            line = line.strip()
            #if a line is M340A, then the lists adds "M340A":["M",340,"A"]
            mut_list.append([line[0],int(line[1:-1]),line[-1]])
    
    return(mut_list)

def optimize(args):
    #given the file and the arguments, optimize the sequence starting and ending at the given position

    file = args.file
    times = args.times
    start = args.start
    end = args.end

    #Create a PDB parser
    parser = PDBParser()

    # Parse the PDB structure from a file
    structure = parser.get_structure("chain_A", f"{file}.pdb")

    # Extract the first model
    model = structure[0]
    chain_A = model['A']  # Select chain A
    
    polypeptide = Polypeptide.Polypeptide(chain_A)
    sequence = str(polypeptide.get_sequence())
    residues = list(chain_A.get_residues())

    # Create a mapping of residue ID to sequence index
    residue_to_index = {residue.get_id(): idx for idx, residue in enumerate(residues)}

    # Define the start and end residue IDs
    start_res_id = (' ', start, ' ') 
    end_res_id = (' ', end, ' ')

    # Get the indices of the start and end residues in the sequence
    start_idx = residue_to_index[start_res_id]
    end_idx = residue_to_index[end_res_id]

    optimize_seq = sequence[start_idx:end_idx+1]

    script_dir = os.path.dirname(os.path.abspath(__file__))
    run_modeller_path = os.path.join(script_dir, 'run_modeller.sh')

    subprocess.run(["bash", run_modeller_path, file, str(start), "X", optimize_seq, str(times), script_dir])


def mutate(args,mut):
    #a full run through of the pipeline
    file = args.file
    mut_pos = mut[1]
    mut_res_oneL = mut[2]
    mut_res_threeL = one_to_three[mut_res_oneL].upper()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    mutate_model_path = os.path.join(script_dir, "mutate_model.py")
    
    subprocess.run(["python", mutate_model_path, f"{file}_wt", str(mut_pos), str(mut_res_threeL)])


def analysis(args,mut):

    file = args.file

    mutate(args,mut)
    mut_pos = mut[1]
    mut_res_oneL = mut[2]
    mut_res_threeL = one_to_three[mut_res_oneL].upper()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    run_foldx_path = os.path.join(script_dir, "run_foldx.sh")
    run_hole_path = os.path.join(script_dir, "run_hole.sh")

    subprocess.run(["bash",run_foldx_path, f"{file}_optimized{mut_res_threeL}{mut_pos}"])
    subprocess.run(["bash",run_hole_path,f"{file}_optimized{mut_res_threeL}{mut_pos}"])


def main():
    args = parser.parse_args()

    optimize(args)
    mut_list = parse_mutation(args.mut_path)

    processes = []
    for mut in mut_list:
        p = multiprocessing.Process(target=analysis, args=(args,mut))
        processes.append(p)
        
        p.start()

    for p in processes:
        p.join()


if __name__ == "__main__":
    main()