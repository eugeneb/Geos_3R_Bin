clear
clc

fclose(instrfind)
%настройки COM порта
Num_com_port='COM15';
baud=115200;
com_port=serial(Num_com_port, 'BaudRate', baud);

%что обрабатывать
settings.LatLonData=1; %сообщение 0х20. Базовый набор географических координат


Bin.preamble=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS

% цикл

    %считывание даннных из порта
    fopen(com_port);
    Bin.data_read=fread(com_port);
    fclose(com_port);
    
    LatLonData.start=0;
    
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
        
        for(k=1:Bin.Num_posts)
            switch(Bin.ncmd(k)) %определение типа сообщения 
                case hex2dec('20')
                    LatLonData.start=Bin.Num_start(k);% начало сообщения 0х20
            end
        end
        
        
        while(settings.LatLonData==1)
            if(LatLonData.start>0)
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
        
    end
    
    