function [ UTC,cycle_d, kol_vo_KA, SignalToNoise, phase, Doppler, H_liter, Range] = GEOS_3R_BIN_KA_data_0x10( data,  KAnumber)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
UTC = GEOS_3R_BIN_bin2num(data(1:8),'double');
cycle_d = data(9)+data(10)*2^8+data(11)*2^16+data(12)*2^24;
kol_vo_KA = data(13)+data(14)*2^8+data(15)*2^16+data(15)*2^24;

ind=0;
for(k=1:kol_vo_KA)
    if(data(4*(-9+14*k)-1)==KAnumber)
        ind=k;
        break
    end
end

if(ind>0)
    SignalToNoise = GEOS_3R_BIN_bin2num(data(4*(-8+14*ind)-3 : 4*(-8+14*ind)),'float');
    phase         = GEOS_3R_BIN_bin2num(data(4*(-1+14*ind)-3 : 4*( 0+14*ind)),'double');
    Doppler       = GEOS_3R_BIN_bin2num(data(4*(-5+14*ind)-3 : 4*(-4+14*ind)),'double');
    Range         = GEOS_3R_BIN_bin2num(data(4*(-7+14*ind)-3 : 4*(-6+14*ind)),'double');
    H_liter       = mod(data(4*(-9+14*ind)-2),2^7)*(-1)^(fix(data(4*(-9+14*ind)-2)/2^7));
else
    SignalToNoise = nan;
    phase         = nan;
    Doppler       = nan;
    Range         = nan
    H_liter       = nan;
end
end

