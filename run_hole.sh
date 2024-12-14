input=$(basename "$1" .pdb) #name of the input PDB name


#if the repaired PDB does not exist, use FoldX to repair the PDB
if [ ! -e "${input}_Repair.pdb" ]; then
	$HOME/foldx/foldx_20241231 --command=RepairPDB --pdb="${input}.pdb"
fi

#write the input file for HOLE
temp_code="coord ${input}_Repair.pdb
radius $HOME/hole2/rad/simple.rad !radius
sphpdb ${input}_out.sph"
echo "$temp_code" > ${input}.inp


#run HOLE and saves the result in tsv
hole < ${input}.inp > ${input}_out.txt
grep -E "mid-|sampled" ${input}_out.txt > ${input}_out.tsv

xmgrace -block ${input}_out.tsv -bxy 1:2 -saveall ${input}.agr
