function plotAllTrajectoriesMIXED(inputCell)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function expects a cell array that contains the xyzt coordinates of
% multiple particles to plot
%
% if cell is named C:
% size(C) = [m, n]
% m is the number of particles and n=1
% in each cell C{i,:} contains the xyzt coordinates of the ith particle.
% Each cell has four columns and they are the xyzt coordinates respectively
% 
%
% All spatial units (xyz) are in microns and time is in seconds
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

axisLabelSize = 16;
viewAz = 45;
viewEl = 30;


for i = 1 : length(inputCell)
    coords = inputCell{i, :};
    % Calculate average z-component velocities, if + user one colormap, if
    % - use a different one
    diffz = diff(coords(:,3));
    difft = diff(coords(:,4));
    vZ = diffz./difft;
    meanVZ = mean(vZ);
    h1 = figure(1);
    if meanVZ>0
        color_line3(coords(:,1), coords(:,2), coords(:,3), coords(:,4),'LineWidth', 5);
    else
        color_line3(coords(:,1), coords(:,2), coords(:,3), coords(:,4),'LineWidth', 2);
    end
    hold on;
end

view(viewAz, viewEl)
axis equal
axis([0 350 0 350 -265 265])
colormap jet
grid on
xlabel('Microns [\mum]', 'FontSize', axisLabelSize)
ylabel('Microns [\mum]', 'FontSize', axisLabelSize)
zlabel('Microns [\mum]', 'FontSize', axisLabelSize)
h = colorbar;
ylabel(h, 'Time [s]', 'FontSize', axisLabelSize)
caxis([0 60])