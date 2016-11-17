clear
clc
fclose(instrfind);

file_name='geos_3MR_F_1_Hz.bin';
Num_com_port='COM67';
baud=115200;
com_port=serial(Num_com_port, 'BaudRate', baud);
fopen(com_port)

bin=0;
tic
while (toc<70)
    bin(end+1:end+512,1)=fread(com_port,512,'uint8');
end

fclose(com_port);

www=fopen(file_name,'w');
fwrite(www,bin,'uint8');