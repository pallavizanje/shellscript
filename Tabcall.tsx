// App.tsx
import React from 'react';
import Tabs from './Tabs';

const App: React.FC = () => {
  const tabData = [
    {
      id: 'home',
      label: 'Home',
      content: <p>Welcome to the home tab!</p>,
    },
    {
      id: 'profile',
      label: 'Profile',
      content: <p>This is your profile tab.</p>,
    },
    {
      id: 'settings',
      label: 'Settings',
      content: <p>Adjust your preferences here.</p>,
    },
  ];

  return (
    <div className="max-w-md mx-auto mt-10">
      <Tabs tabs={tabData} />
    </div>
  );
};

export default App;
