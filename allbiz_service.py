#!/usr/bin/python
# -*- coding: utf-8 -*-

from datetime import datetime, timedelta
from iso8601 import parse_date
from pytz import timezone
import urllib
import json
import os


def convert_time(date):
    date = datetime.strptime(date, "%d/%m/%Y %H:%M:%S")
    return timezone('Europe/Kiev').localize(date).strftime('%Y-%m-%dT%H:%M:%S.%f%z')


def convert_time_item(date):
    date = datetime.strptime(date, "%d/%m/%Y")
    res_date = date.strftime('%Y-%m-%dT%H:%M:%S')
    return "{}+{}".format(res_date, "02:00")

def subtract_min_from_date(date, minutes, template):
    date_obj = datetime.strptime(date.split("+")[0], template)
    return "{}+{}".format(date_obj - timedelta(minutes=minutes), date.split("+")[1])


def convert_datetime_to_allbiz_format(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%d/%m/%Y %H:%M")
    return day_string

def convert_date_plan_to_allbiz_format(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%d/%m/%Y")
    return day_string


def convert_date_plan_tender_to_allbiz_format(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%m/%Y")
    return day_string

def convert_date_plan_to_allbiz_format_year(isodate):
    iso_dt = parse_date(isodate)
    day_string = iso_dt.strftime("%Y")
    return day_string


def convert_string_from_dict_allbiz(string):
    return {
        u"грн.": u"UAH",
        u"True": u"1",
        u"False": u"0",
        u"Відкриті торги": u"aboveThresholdUA",
        u"Відкриті торги з публікацією англ. мовою": u"aboveThresholdEU",
        u"Переговорна процедура для потреб оборони": u"aboveThresholdUA.defense",
        u'Класифікацiя предмета закупівлi за ДК021:2015': u'ДК021',
        u'Код ДК (ДК003)': u'ДК003',
        u'Код ДК (ДК018)': u'ДК018',
        u'Код ДК (ДК015)': u'ДК015',
        u'з урахуванням ПДВ': True,
        u'без урахуванням ПДВ': False,
        u'Очiкування пропозицiй': u'active.tendering',
        u'Перiод уточнень': u'active.enquiries',
        u'Аукцiон': u'active.auction',
        u'Прекваліфікація': u'active.pre-qualification',
        u'Квалiфiкацiя переможця': u'active.qualification',
        u'Оскарження прекваліфікації': u'active.pre-qualification.stand-still',
        u'вимога': u'claim',
        u'не задоволено': u'declined',
        u'дано відповідь': u'answered',
        u'вирішено': u'resolved',
        u'відхилено': u'declined',
        u'недійсно': u'invalid',
        u'award_ignored': u'ignored',
        u'Так': True,
        u'Ні': False,
        u'на розглядi': u'pending',
        u'На розгляді': u'pending',
        u'не вирішено(обробляється)': u'pending',
        u'відмінено': u'cancelled',
        u'відмінена': u'cancelled',
        u'Переможець': u'active',
        u'ящик': u'BX',
        u'open_belowThreshold': u'belowThreshold',
        u'limited_reporting': u'reporting',
        u'open_aboveThresholdUA': u'aboveThresholdUA',
        u'Код ДК 021-2015 (CPV)': u'ДК021',
        u'Запланований': u'scheduled',
        u'(робочі)': u'working',
        u'(банківські)': u'banking',
        u'(календарні)': u'calendar',
        u'Аванс': u'prepayment',
        u'Пiсляоплата': u'postpayment',
        u'виконання робіт': u'executionOfWorks',
        u'поставка товару': u'deliveryOfGoods',
        u'надання послуг': u'submittingServices',
        u'підписання договору': u'signingTheContract',
        u'дата подання заявки': u'submissionDateOfApplications',
        u'дата виставлення рахунку': u'dateOfInvoicing',
        u'дата закінчення звітного періоду': u'endDateOfTheReportingPeriod',
        u'інша подія': u'anotherEvent',
        u'Послуги': u'services',
        u'Товари': u'goods',
        u'Роботи': u'works',
        u'Класифікацiя предмета закупівлi за ДК 021:2015': u'ДК021',
        u'Конкурентний діалог': u'competitiveDialogueUA',
        u'Конкурентний діалог з публікацією англ. мовою': u'competitiveDialogueEU',
        u'Визначення переможців': u'active.qualification',
        u'Відкриті торги для закупівлі енергосервісу': u'esco',
        u'співфінансування з бюджетних коштів': u'budget',
        u'Очікування переведення': u'active.stage2.pending',
        u'Укладання рамкової угоди': u'closeFrameworkAgreementUA',
        u'Пропозицiї розглянуто': u'active.qualification',
        u'Завершена': u'complete',
        u'відкликано скаржником': u'stopping',
        u'USA': u'Сполучені Штати Америки',
        u'Не визначено': u'Не відображене в інших розділах',
        u'без відповіді': u'ignored',
        u'відкликано скаржником': u'stopping',
        u'Без ответа': u'ignored',
        u'prozorroytenderowner@gmail.com prozorroytenderowner@gmail.com': u'Тестовий Замовник 2',
        u'+38(099)353-10-28': u'380664445566',
    }.get(string, string)


def adapt_procuringEntity(role_name, tender_data):
    if role_name == 'tender_owner':
        tender_data['data']['procuringEntity']['name'] = u"prozorroytenderowner"
        tender_data['data']['procuringEntity']['address']['postalCode'] = u"01001"
        tender_data['data']['procuringEntity']['address']['region'] = u"м. Київ"
        tender_data['data']['procuringEntity']['address']['locality'] = u"Київ"
        tender_data['data']['procuringEntity']['address']['streetAddress'] = u"Вулична вулиця"
        tender_data['data']['procuringEntity']['identifier']['legalName'] = u"prozorroytenderowner"
        tender_data['data']['procuringEntity']['identifier']['id'] = u"12312312"
        tender_data['data']['procuringEntity']['contactPoint']['name'] = u"бла бла "
        tender_data['data']['procuringEntity']['contactPoint']['telephone'] = u"+38(099)353-10-28"
        tender_data['data']['procuringEntity']['contactPoint']['url'] = u"http://webpage.com.ua"
        if tender_data['data'].has_key('procurementMethodType'):
            if "above" in tender_data['data']['procurementMethodType']:
                tender_data['data']['tenderPeriod']['startDate'] = subtract_min_from_date(
                    tender_data['data']['tenderPeriod']['startDate'], 1, '%Y-%m-%dT%H:%M:%S.%f')
        for item in tender_data['data']['items']:
            if item['classification']['description'] == u"Не відображене в інших розділах":
                item['classification']['description'] = u"Не визначено"
    return tender_data


def adapt_delivery_data(tender_data):
    for index in range(len(tender_data['data']['items'])):
        value = tender_data['data']['items'][index]['deliveryAddress']['region']
        if value == u"місто Київ":
            tender_data['data']['items'][index]['deliveryAddress']['region'] = u"Київ"
    return tender_data


def adapt_view_tender_data(value, field_name):
    if 'amount' in field_name:
        value = float(value.replace(" ", ""))
    elif 'currency' in field_name and 'awards' in field_name:
        value = value.split(' ')[-1]
    elif 'minimalStep.amount' in field_name:
        value = float("".join(value.split(" ")[:-4]))
    # elif 'unit.name' in field_name:
    #     value = value.split(' ')[1]
    elif 'quantity' in field_name:
        value = float(value.replace(",", "."))
    elif 'questions' in field_name and '.date' in field_name:
        value = convert_time(value.split(' - ')[0])
    elif 'Date' in field_name:
        value = convert_time(value)
    elif 'NBUdiscountRate' in field_name:
        value = round(float(value[0:-1]) / 100, 5)
    elif 'minimalStepPercentage' in field_name:
        value = round(float(value[0:-1]) / 100, 5)
    elif 'maxAwardsCount' in field_name:
        value = int(value)
    elif 'agreementDuration' in field_name:
        l = value.split(" ")
        value = "P{}Y{}M{}D".format(l[0], l[2], l[4] )
    elif 'yearlyPaymentsPercentageRange'in field_name:
        value = round(float(value.split(" ")[-1][:-1]) / 100, 5)
    return convert_string_from_dict_allbiz(value)


def adapt_view_lot_data(value, field_name):
    if 'value.amount' in field_name:
        value = float("".join(value.split(' ')[:-4]))
    elif 'minimalStep.currency' in field_name:
        value = value.split(' ')[-1]
    elif 'currency' in field_name:
        value = value.split(' ')[-4]
    elif 'valueAddedTaxIncluded' in field_name:
        value = ' '.join(value.split(' ')[-3:]).strip()
    elif 'minimalStep.amount' in field_name:
        value = float("".join(value.split(' ')[:-1]))
    return convert_string_from_dict_allbiz(value)


def adapt_view_item_data(value, field_name):
    if 'unit.name' in field_name:
        value = ' '.join(value.split(' ')[1:])
    elif 'quantity' in field_name:
        value = float(value.split(' ')[0])
    elif 'Date' in field_name:
        value = convert_time(value)
    return convert_string_from_dict_allbiz(value)


def get_related_elem_description(tender_data, feature, item_id):
    if item_id == "":
        for elem in tender_data['data']['{}s'.format(feature['featureOf'])]:
            if feature['relatedItem'] == elem['id']:
                return elem['description']
    else:
        return item_id


def custom_download_file(url, file_name, output_dir):
    urllib.urlretrieve(url, ('{}/{}'.format(output_dir, file_name)))


def add_second_sign_after_point(amount):
    amount = str(repr(amount))
    if '.' in amount and len(amount.split('.')[1]) == 1:
        amount += '0'
    return amount


def get_upload_file_path():
    return os.path.join(os.getcwd(), 'src/robot_tests.broker.tendersallbiz/testFileForUpload.txt')