function plotTrajectories2D(inputCell)

for i = 1 : length(inputCell)
    coords = inputCell{i, :};
    scatter(coords(:,1), -1.*coords(:,2),[], coords(:,3),'filled');
    hold on;
end