clear; close all; clc;

vidObj = VideoWriter('Vertical_Maze_Dubai-2K_ours.avi');  
vidObj.Quality = 100;  
vidObj.FrameRate = 25;  
open(vidObj);  
tic;
for i=0:3515
    fname=strcat('./dubai_building_output/frame_',num2str(i,'%.4d'),'_building.png');  
    adata=imread(fname);  
    writeVideo(vidObj,adata); 
    if mod(i,100) == 0
        toc;
        i
        tic;
    end
end 
close(vidObj);