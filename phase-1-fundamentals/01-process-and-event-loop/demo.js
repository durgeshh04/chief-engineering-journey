// Example-1
// console.log("1 - Start");

// setTimeout(() => console.log("2 - setTimeout"), 0);

// Promise.resolve().then(() => console.log("3 - Promise"));

// console.log("4 - End");

// Example-2
// Promise.resolve().then(() => {
//     console.log("3 - Promise");
//     Promise.resolve().then(() => console.log("3.5 - nested Promise"));
//   });

// Example-3
setTimeout(() => {
  console.log("1-Hello code");
  Promise.resolve().then(() => {
    console.log("3 - Promise");
    Promise.resolve().then(() => console.log("3.5 - nested Promise"));
  });
  console.log("2-Hello code");
}, 0);
