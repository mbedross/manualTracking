function [video] = generateVideo(traj)

nstep = length(traj);
figure('units','normalized','outerposition',[0 0 1 1])

% Generate the video
for t = 1 : nstep

    x(1:t) = traj(1:t, 1);
    y(1:t) = traj(1:t, 2);
    z(1:t) = traj(1:t ,3);
    
    xNow = traj(t, 1);
    yNow = traj(t, 2);
    zNow = traj(t ,3);

    %* Create Plot
    
    plot3(x,y,z,'LineWidth',2)
    hold on;
    plot3(xNow,yNow,zNow,'*', 'MarkerSize',20, 'LineWidth',2)
    view([45 45]);  % Rotate to get a better view 
    grid on           % Add a grid to aid perspective
    axis([0 360 0 360 min(traj(:,3)) max(traj(:,3))])
    xlabel('\mum'); ylabel('\mum'); zlabel('\mum');
    set(gca,'FontSize',16)
    hold off;
    print(sprintf('trajectories_%d.png',t),'-dpng','-r300')

    %* Save frame
    %video(t) = getframe;

end

% v = VideoWriter('my_trajectory_video.avi')
% v.Quality = 100;
% v.FrameRate = 15;
% open(v)
% writeVideo(v,video)
% close(v)
% 
% % Generate the still plot
% 
% figure(2)
% color_line3(traj(:,1), traj(:,2), traj(:,3), traj(:,4),'LineWidth', 2);
% view(viewAz, viewEl)
% axis equal
% colormap jet
% grid on
% xlabel('Microns [\mum]', 'FontSize', axisLabelSize)
% ylabel('Microns [\mum]', 'FontSize', axisLabelSize)
% zlabel('Microns [\mum]', 'FontSize', axisLabelSize)
% h = colorbar;
% ylabel(h, 'Time [s]', 'FontSize', axisLabelSize)
% print('trajectories.png','-dpng','-r1000')