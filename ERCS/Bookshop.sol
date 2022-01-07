// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";

contract Bookshop {

    //Instancia del contrato token
    ERC20Basic private token;

    //Dirección de disney(Owner)
    address payable public owner;

    //constructor
    constructor() public {
        token = new ERC20Basic(10000);
        owner = msg.sender;
    }

    //Estructura de datos para almacenar a los clientes
    struct client {
        uint tokens;
        string [] books;
    }

    //Mapping para el registro de clientes
    mapping(address => client) public clients;

    //Función para establecer el precio de un Token
    function priceTokens(uint _numTokens) internal pure returns(uint) {
        //Conversión de Tokens a Ethers: 1 Token -> 1 Ether
        return _numTokens*(1 ether);
    }

    //Función para comprar tokens
    function buyTokens(uint _numTokens) public payable {
        //Establecer el precio de los tokens
        uint cost = priceTokens(_numTokens);

        //Se evalua el dinero que el cliente paga por los tokens
        require(msg.value >= cost, "Buy fewer tokens or pay with more ethers");

        //Diferencia de lo que el cliente paga
        uint returnValue = msg.value - cost;

        //Se devuelve la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);

        //Obtención del número de tokens disponibles
        uint balance = balanceOf();
        require(_numTokens <= balance, "Buy a smaller number of tokens");

        //Se transfiere el numero de tokens al cliente
        token.transfer(msg.sender, _numTokens);

        //Registro de tokens comprados
        clients[msg.sender].tokens += _numTokens;
    }


    //Balance de tokens del contrato
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Visualizar el número de tokens restantes de un cliente
    function tokensAvailables() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //Función para generar más tokens
    function generateTokens(uint _numTokens) public unique(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }

    //Modificador para controlar las funciones ejecutables
    modifier unique(address _dir) {
        require(_dir == owner, "You do not have permissions.");
        _;
    }

    //////////////////GESTION//////////////////

    event buy_book(string, uint, address);
    event add_book(string, uint);
    event remove_book(string);

    //Estructura de la atracción
    struct book {
        string name;
        uint price;
        bool state;
    }

    //Mapping para relacionar un nombre de una atracción con una estructura de datos
    mapping (string => book) public mappingBooks;

    string [] booksList;

    //Mapping de cliente e historial
    mapping(address => string []) recordBooks;

    //Crear nuevos libros
    function addBooks(string memory _name, uint _price) public unique(msg.sender) {
        mappingBooks[_name] = book(_name, _price, true);
        booksList.push(_name);
        emit add_book(_name, _price);
    }

    //Eliminar atracciones
    function removeBooks(string memory _name) public unique(msg.sender) {
        mappingBooks[_name].state = false;
        emit remove_book(_name);
    }

    //Visualizar libros
    function booksAvailable() public view returns (string [] memory) {
        return booksList;
    }

    //Función para pagar
    function buyBook(string memory _name) public {
        uint price_token = mappingBooks[_name].price;
        require(mappingBooks[_name].state == true, "Not available");
        require(price_token <= tokensAvailables(), "You need more tokens.");

        //Necesario crear función en ERC20.sol
        token.transfer_books(msg.sender, address(this), price_token);
        //Añadir al historial
        recordBooks[msg.sender].push(_name);

        emit buy_book(_name, price_token, msg.sender);
    }

    //Ver el historial completo
    function record() public view returns(string [] memory) {
        return recordBooks[msg.sender];
    }

    //Función para que un cliente pueda devolver tokens
    function returnTokens(uint _numTokens) public payable {
        require(_numTokens > 0, "You need to return a positive amount of tokens.");
        require(_numTokens <= tokensAvailables(), "You don't have the tokens you want to return.");
        token.transfer_books(msg.sender, address(this), _numTokens);
        msg.sender.transfer(priceTokens(_numTokens));
    }

}