## Projekt na przedmiot Zaawansowane Systemy Cyfrowe 
### Układ FPGA realizujący komunikację w standardzie OpenVPN 

**Autorzy:** Patryk Duda, Michał Zagórski

### Cel projektu:
celem projektu jest zaprogramowanie dostępnego ukladu FPGA jako modułu umożliwiającego przetwarzanie na potrzeby sieci VPN w standardzie OpenVPN.
Moduł ma stanowić element połączenia między komputem -- stacją roboczą, a dedykowanym serwerem VPN.
W wersji podstawowej planujemy wykorzystać szyfrowanie oparte o klucz statyczny (pre-shared).

Potrzebne źródło:

[Dokumenty OpenVPN (Security Overview)](https://openvpn.net/index.php/open-source/documentation/security-overview.html)

[Dokumenty OpenVPN - HowTo](https://openvpn.net/index.php/open-source/documentation/howto.html)

[OpenVPN - Wiki](https://community.openvpn.net/openvpn)
Strona dokumentacji man dla openvpn

### Etapy tworzenia projektu
* Wybór chipu do obsługi sieci (Warstwa 1, czy warstwa 2)
* _Implementacja MII (Media Independent Interface)_
* _Implementacja warstwy 2. - MAC_
* _Implementacja sum kontrolnych CRC_
* Implementacja obsługi IPv6
* Obsługa warstwy 4. - protokół UDP (tylko)
* Obsługa szyfrowania (AES 128 CDC)
* Implementacja funkcji skrótu (jeszcze nie ustalona)




