clear
clc

%fclose(instrfind)
%настройки COM порта
Num_com_port='COM15';
baud=115200;
com_port=serial(Num_com_port, 'BaudRate', baud);

%что обрабатывать
settings.LatLonData=1; %сообщение 0х20. Базовый набор географических координат
settings.phData=1;     %сообщение 0х10.

Bin.preamble=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS

%настройки бинарного протокола приемника
for(k=1:8)
Bin.data_write(k)=Bin.preamble(k);
end
Bin.data_write(9:16)=[hex2dec('4F'), 0, 1, 0, 0, 0, hex2dec('01'), 0];
BinDataWrite(Bin.data_write, com_port);


% цикл

    %считывание даннных из порта
    fopen(com_port);
    Bin.data_read=fread(com_port,512);
    Bin.data_read(end+1:1024)=fread(com_port,512);
    Bin.data_read(end+1:1536)=fread(com_port,512);
    Bin.data_read(end+1:2048)=fread(com_port,512);
    fclose(com_port);
    
    LatLonData.start=0;
    phData.start=0;
    
    Bin.Num_posts=0;% колличество полученных сообщений
    for(k=1:(length(Bin.data_read)-10)) % цикл поиска начала сообщения и их колличества
       logik_Matrix(1:8)=(Bin.data_read(k:k+7)==Bin.preamble(1:8));
       logik=logik_Matrix(1);
       for (ind=2:8)
            logik=logik&logik_Matrix(ind); 
       end
       
       if(logik)
           Bin.Num_posts=Bin.Num_posts+1; %инкремент колличства сообщений
           Bin.Num_start(Bin.Num_posts)=k;% ячейка начала сообщения
       end
    end
    
    if (Bin.Num_posts>0) % если сообщения получены из приемника
        Bin.datN=Bin.data_read(Bin.Num_start+11)*256+Bin.data_read(Bin.Num_start+10); %количество слов в сообщение 
        Bin.ncmd=Bin.data_read(Bin.Num_start+9)*256+Bin.data_read(Bin.Num_start+8); % номер сообщения (о чем сообщение)
        
        for(k=1:Bin.Num_posts) %определение типа сообщения (его номер)
            switch(Bin.ncmd(k)) 
                case hex2dec('20')
                    if(LatLonData.start==0) %обрабатываем самые ранние данные
                        LatLonData.start=Bin.Num_start(k);% начало сообщения 0х20
                    end
                case hex2dec('10')
                    if(phData.start==0) % т.е. те данные, которые приняты полностью
                        phData.start=Bin.Num_start(k);% начало сообщения 0х10    
                    end
            end
        end
        
        
        while(settings.LatLonData==1) %обработка сообщения 0х20
            if((LatLonData.start>0)&(LatLonData.start<length(Bin.data_read)-256))
                fprintf('\n ____________0x20___________ \n')
                tmp=nan;
                for(k=1:8) %UTC
                    tmp(k)=Bin.data_read(LatLonData.start+11+k);
                end
                LatLonData.UTC=bin2num(tmp,'double');
                fprintf('UTC (c 01.01.2008): %9.0f sec \n', LatLonData.UTC)
                %
                %Lat and Lon
                for(k=1:8) %Lat
                    tmp(k)=Bin.data_read(LatLonData.start+19+k);
                end
                LatLonData.Lat=bin2num(tmp,'double')*180/pi;
                fprintf('Lat: %f \n', LatLonData.Lat)
                
                for(k=1:8) %Lon
                    tmp(k)=Bin.data_read(LatLonData.start+27+k);
                end
                LatLonData.Lon=bin2num(tmp,'double')*180/pi;
                fprintf('Lon: %f \n', LatLonData.Lon)
                plot(LatLonData.Lon,LatLonData.Lat,'.b','MarkerSize',15)
                plot_google_map
            end
            break;
        end
        
        while(settings.phData==1) %обработка сообщения 0х10
            if((phData.start>0)&(phData.start<length(Bin.data_read)-256))
                fprintf('\n ____________0x10___________ \n')
                tmp=nan;%UTC
                for(k=1:8) 
                    tmp(k)=Bin.data_read(phData.start+11+k);
                end
                phData.UTC=bin2num(tmp,'double');
                fprintf('UTC (c 01.01.2008): %9.0f sec \n', phData.UTC) %print UTC
                
                tmp=nan;%колличество КА, по которым передается измерительная информация
                for(k=1:4) 
                    tmp(k)=Bin.data_read(phData.start+23+k);
                end
                phData.NumKA=bin2num(tmp,'int');
                fprintf('NUM KA: %d  \n', phData.NumKA) %print число КА в решение
                
                phData.inf(1:96)=nan;
                for(k=1:phData.NumKA)
                    
                end
            end
        break;    
        end
    end
    
    