# CS551K-Group4

# Team names:
- Mateusz
- Saunak
- Calum
- Paa Kofi
- Aryan Batheja


TODO:
- [ ] Document the data interface to tell others how they should bind to them:
  - [ ] 2 positions + obstacle map and a direction out for Voldy
  - [ ] Calum should make his own state machine that can be then acted on within my lost state
  - [ ] Up to the other 2 how they want to implement that
- [ ] add rotation and optimisations for that (low priority ATM)
- [ ] goal submission failures still exist (FIX) (Do they, or just not enough tasks?)
- [ ] check if diagonal movement impacts them gettign stuck more
- [ ] new failure mode, starts going right until hits the wall then works again??? might have sth to do with failed movment while carrying
- [ ] a terrain,gap,terrain setup paralyzes agents in exploration
- [ ] when n wall found do a check to purge dispensers that are too close
- [ ] when rebinding, do a check for current state and update nav goals to the new bind
