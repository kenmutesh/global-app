// const baseUrl = 'http://10.0.2.2:8000/api/v1/';
const baseUrl = 'http://stocks.uoemcu.co.ke/api/';
const loginUrl = baseUrl + 'login';
const registerUrl = baseUrl + '/register';
const logoutUrl = baseUrl + '/logout';


const stores = baseUrl + 'branches';
const clockin = baseUrl + 'clockins/active';
const clockout = baseUrl + 'clockout';
const saveClockin = baseUrl + 'saveClockin';

const productsUrl = baseUrl + 'products';
const saveProductUrl = baseUrl + 'storeProducts';


const serverError = 'Server error';
const unauthorized = 'Unauthenticated';
const somethingWentWrong = 'Something went wromg! Try again';