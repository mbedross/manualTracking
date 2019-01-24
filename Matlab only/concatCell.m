function [output] = concatCell(inputCell)


output = inputCell{1,1};
for i = 2 : length(inputCell)
    output = [output; inputCell{i,1}];
end
