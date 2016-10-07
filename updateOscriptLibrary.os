#Использовать json
#Использовать gitrunner

Процедура ОбеспечитьПустойКаталог(Знач ПутьККаталогу)
    
    ФайлКаталог = Новый Файл(ПутьККаталогу);
    Если Не ФайлКаталог.Существует() Тогда
        СоздатьКаталог(ФайлКаталог.ПолноеИмя);
    ИначеЕсли ФайлКаталог.ЭтоКаталог() Тогда
        УдалитьФайлы(ФайлКаталог.ПолноеИмя, ПолучитьМаскуВсеФайлы());
    Иначе
        ВызватьИсключение "Путь " + ФайлКаталог.ПолноеИмя + " не является каталогом. Выгрузка невозможна";
    КонецЕсли;
    
КонецПроцедуры

КаталогСборки = ОбъединитьПути(ТекущийКаталог(), "build");
КаталогИсходников = ОбъединитьПути(КаталогСборки, "src");
КаталогСобранныхПакетов = ОбъединитьПути(КаталогСборки, "out");

ОбеспечитьПустойКаталог(КаталогСборки);
ОбеспечитьПустойКаталог(КаталогИсходников);
ОбеспечитьПустойКаталог(КаталогСобранныхПакетов);

Сервер = "https://api.github.com";
Соединение = Новый HTTPСоединение(Сервер);

Ресурс = "/orgs/oscript-library/repos";
Заголовки = Новый Соответствие();
Заголовки.Вставить("Accept", "application/vnd.github.v3+json");
Заголовки.Вставить("User-Agent", "oscript-library-autobuilder");

Запрос = Новый HTTPЗапрос(Ресурс, Заголовки);
Ответ  = Соединение.Получить(Запрос);

Если Ответ.КодСостояния <> 200 Тогда
    Сообщить(Ответ.ПолучитьТелоКакСтроку());
    ВызватьИсключение Ответ.КодСостояния;
КонецЕсли;

ПарсерJSON = Новый ПарсерJSON();
ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(Ответ.ПолучитьТелоКакСтроку());
Для Каждого Репозиторий Из ДанныеОтвета Цикл
    ИмяРепозитория = Репозиторий.Получить("name");

    ПутьКРепозиторию = Репозиторий.Получить("clone_url");
    ЭтоФорк = Репозиторий.Получить("fork");
    КаталогРепозитория = ОбъединитьПути(КаталогИсходников, ИмяРепозитория);
    
    ГитМенеджер = Новый ГитРепозиторий();
    ГитМенеджер.УстановитьРабочийКаталог(КаталогИсходников);
    ГитМенеджер.КлонироватьРепозиторий(ПутьКРепозиторию);
    
    Сообщить("Репозиторий успешно склонирован: " + ИмяРепозитория);
    
    ГитРепозиторий = Новый ГитРепозиторий();
    ГитРепозиторий.УстановитьРабочийКаталог(КаталогРепозитория);
    
    ГитРепозиторий.ПерейтиВВетку("master");
    ГитРепозиторий.Получить();

	Если ЭтоФорк Тогда
        Сообщить("Это форк. Получаю информацию о родителе");
		РесурсРепозиторий = "/repos/oscript-library/" + ИмяРепозитория;
    	ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, Заголовки);
		ОтветРепозиторий  = Соединение.Получить(ЗапросРепозиторий);
        ДанныеОтветаРепозиторий = ПарсерJSON.ПрочитатьJSON(ОтветРепозиторий.ПолучитьТелоКакСтроку());
        ПутьКРепозиториюРодителю = ДанныеОтветаРепозиторий.Получить("parent").Получить("clone_url");
        
        ГитРепозиторий.ДобавитьВнешнийРепозиторий("origin1", ПутьКРепозиториюРодителю);
		ГитРепозиторий.Получить("origin1", "master");

        Сообщить("Информация о родителе получена");
    КонецЕсли;
    
    ГитРепозиторий.ОбновитьПодмодуль(Истина, Истина);
    
    // ГитРепозиторий.Отправить();

    СтрокаКоманды = СтрШаблон("opm build %1", КаталогРепозитория);
    КодВозврата = 0;
    ЗапуститьПриложение(СтрокаКоманды, КаталогСобранныхПакетов, Истина, КодВозврата);
    
    Если КодВозврата = 0 Тогда
        Сообщение = СтрШаблон("Пакет <%1> успешно собран", ИмяРепозитория);    
    Иначе
        Сообщение = СтрШаблон("Ошибка сборки пакета <%1>", ИмяРепозитория); 
    КонецЕсли;
    Сообщить(Сообщение);
    
КонецЦикла;
