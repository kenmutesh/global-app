// const baseUrl = 'http://10.0.2.2:8000/api/v1/';
const baseUrl = 'http://stocks.uoemcu.co.ke/api/';
const loginUrl = baseUrl + 'login';
const registerUrl = baseUrl + '/register';
const logoutUrl = baseUrl + '/logout';

const branchesUrl = baseUrl + 'branches';
const storesUrl = baseUrl + 'stores'; //store has branches
const clockin = baseUrl + 'clockins/active';
const clockout = baseUrl + 'clockins/clockout';
const saveClockin = baseUrl + 'clockins/clockin';

const productsUrl = baseUrl + 'products';
const saveProductUrl = baseUrl + 'products/store';
const userProductUrl = baseUrl + 'user/products';

const serverError = 'Server error';
const unauthorized = 'Unauthenticated';
const somethingWentWrong = 'Something went wromg! Try again';
