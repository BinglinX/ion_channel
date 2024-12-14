#!/bin/bash



# Set the input file name based on the command line argument
original_input="$1"   # Input file without extension
final_output="${original_input}_Repair.pdb"  # Fixed output file name

temp_suffix="_Repair"

# Set the initial input file for the loop
input="${original_input}"

# Loop 10 times to repair the file
for i in {1..10}
do

    echo "${pwd}"
    # Execute the command
    $HOME/foldx/foldx_20241231 --command=RepairPDB --pdb="${input}.pdb"


    # Save the current input for deletion after the next iteration
    previous_input="${input}"

    # Update the input for the next iteration
    input="${input}${temp_suffix}"

    # Delete the previous file (except in the first iteration)
    if [ $i -gt 1 ]; then
	    rm "${previous_input}.pdb"
	    rm "${previous_input}.fxout"
    fi

    if [ $i -eq 10 ]; then
        rm "${previous_input}_${temp_suffix}.fxout"
    fi
done

# Rename the final file to the fixed output name
mv "${input}.pdb" "${final_output}"
