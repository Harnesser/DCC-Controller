//
// Generating a DCC Signal using Timer2 and the Waveform Generator
//

#include <avr/io.h>
#include <avr/interrupt.h> 

#define LED_PIN 5  // digital pin #13 (portb)
#define LED_ON() PORTB |= _BV(LED_PIN)
#define LED_OFF() PORTB &= ~_BV(LED_PIN)

#define PIN_14 4
#define LED1_ON() PORTB |= _BV(PIN_14)
#define LED1_OFF() PORTB &= ~_BV(PIN_14)

byte timer2_target = 100;
unsigned int mycount = 0;

void setup() {
  
  // Enable Timer2 
  OCR2A = timer2_target;
  bitSet(TCCR2B, CS22);
  bitSet(TCCR2B, CS21);
  bitSet(TCCR2B, CS20);
  
  pinMode(13,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(12,OUTPUT);
  
  digitalWrite(9,LOW);
  // Enable Timer2 interrupt
  bitSet(TIMSK2, OCIE2A); 
  sei();  
}

ISR( TIMER2_COMPA_vect ){
  mycount += 1;

  if( mycount == 2 ) {
    LED_OFF();
    LED1_ON();
  } else if (mycount == 4    ) {
    LED_ON();
    LED1_OFF();
    mycount = 0;
  }  
  TCNT2 = 0;
  
};


void loop(){
}


