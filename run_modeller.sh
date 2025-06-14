#!/bin/bash

file=$1
respos=$2
restyp=$3
filterseq=$4
times=$5
path=$6

# Function to convert one-letter code to three-letter code
one_to_three_letter_code() {
    case "$1" in
        A) echo "ALA" ;;
        R) echo "ARG" ;;
        N) echo "ASN" ;;
        D) echo "ASP" ;;
        C) echo "CYS" ;;
        E) echo "GLU" ;;
        Q) echo "GLN" ;;
        G) echo "GLY" ;;
        H) echo "HIS" ;;
        I) echo "ILE" ;;
        L) echo "LEU" ;;
        K) echo "LYS" ;;
        M) echo "MET" ;;
        F) echo "PHE" ;;
        P) echo "PRO" ;;
        S) echo "SER" ;;
        T) echo "THR" ;;
        W) echo "TRP" ;;
        Y) echo "TYR" ;;
        V) echo "VAL" ;;
        *) echo "Unknown" ;;
    esac
}

# Check if restyp is 'X'
if [[ "$restyp" == "X" ]]; then
    for (( i=1; i<=times; i++ )); do
    
        if [[ i -eq 1 ]]; then
            cp "${file}.pdb" "${file}_wt.pdb"
        fi

        # Loop through each letter in filterseq
        for (( j=0; j<${#filterseq}; j++ )); do #a C-style loop
            # Extract the current letter from filterseq
            res=${filterseq:$j:1}

            # Convert res to the three-letter code
            res_three=$(one_to_three_letter_code "$res")
            
            # Run the python script mutate_residue.py with N (respos) and res (current letter as three-letter code)
            python "${path}/self_mutate.py" "${file}_wt" "$((respos + j))" "$res_three"
            if [[ j -lt ${#filterseq} ]]; then
                mv "${file}_wt_optimized.pdb" "${file}_wt.pdb"
            fi
        done
    done
else
    # Convert the one-letter restyp to three-letter code
    restyp_three=$(one_to_three_letter_code "$restyp")
    
    # Run python mutate_residue.py with respos and three-letter restyp
    python "${path}/mutate_model.py" "${file}_wt_optimized" "$respos" "$restyp_three"
    mv "${file}_wt_optimized${restyp_three}${respos}.pdb" "${file}${restyp_three}${respos}.pdb"
fi
