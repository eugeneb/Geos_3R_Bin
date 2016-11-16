function [ out ] = GEOS_3R_BIN_potocRead_ncmd( ncmd, com_port)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
preamble_and_ncmd(1:8,1)=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOS-3R
ncmd=str2num(dec2bin(ncmd)); %добавляем к преамбуле номер сообщения (ncmd)
preamble_and_ncmd(9:10,1)=0;%!!! preamble_and_ncmd(10,1)==0 согласно протоколу
for(k=1:8)
    preamble_and_ncmd(9,1)=preamble_and_ncmd(9,1)+fix(mod(ncmd,10^k)/10^(k-1))*2^(k-1);
end
poisk(1:10,1)=0; % массив поиска, он будет сравниваться с preamble_and_ncmd
while(1==1)
    logik=0;
    data=nan;
    poisk=nan;
    data(1:512,1)=fread(com_port,512,'uint8');
    data(513:1024,1)=fread(com_port,512,'uint8');
    data(1025:1536,1)=fread(com_port,512,'uint8');
    data(1537:2048,1)=fread(com_port,512,'uint8');
    for(k=1:2048-50)
        poisk(1:10,1)=data(k:k+9,1);
        if(poisk(1:10,1)==preamble_and_ncmd)
            break
        end
    end
    if(poisk(1:10,1)==preamble_and_ncmd)
        
        if(logik==1)
            break
        end
    end
end

