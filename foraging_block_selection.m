function next_block = foraging_block_selection(TrialRecord)
% FORAGING_BLOCK_SELECTION
% Defines the master progression sequence across experimental blocks.
% Block Mapping: 1=Fast Forest, 2=Slow Forest, 3=Break, 4=Instructions, 5=Practice

persistent block_idx;

% Change the array below to customize the block order played during a session
block_sequence = [4, 5, 1, 3, 2]; 

% Initialize or increment the index
if isempty(block_idx) || TrialRecord.CurrentTrialNumber <= 1
    block_idx = 1;
else
    block_idx = block_idx + 1;
end

% Safety: Wrap around if we exceed the sequence length
if block_idx > length(block_sequence)
    block_idx = 1;
end

next_block = block_sequence(block_idx);

end
