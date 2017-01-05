function [ t_gps, drift ] = GEOS_3R_BIN_navi_task_0x13( data )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
t_gps = GEOS_3R_BIN_bin2num(data(4*7-3:4*8),'double');
drift = GEOS_3R_BIN_bin2num(data((4*7-3:4*8) + 4*8),'double');

end

