import React, { useState, useRef } from "react";
import { useFormik } from "formik";
import * as Yup from "yup";
import { AgGridReact } from "ag-grid-react";
import "ag-grid-community/styles/ag-grid.css";
import "ag-grid-community/styles/ag-theme-alpine.css";

// Fake search API
const fetchSearchResults = (query: string) => {
  return new Promise<{ id: number; name: string; description: string }[]>(
    (resolve) => {
      setTimeout(() => {
        resolve([
          { id: 1, name: "John Doe", description: "Developer" },
          { id: 2, name: "Jane Smith", description: "Designer" },
        ]);
      }, 500);
    }
  );
};

export default function UpdateForm() {
  const [searchResults, setSearchResults] = useState<
    { id: number; name: string; description: string }[]
  >([]);
  const [selectedRecord, setSelectedRecord] = useState<any>(null);
  const [showModal, setShowModal] = useState(false);
  const [showGridModal, setShowGridModal] = useState(false);
  const [submitMessage, setSubmitMessage] = useState("");
  const [showForm, setShowForm] = useState(false);

  const gridRef = useRef<AgGridReact<any>>(null);

  // ✅ Row data with isSelected
  const [rowData, setRowData] = useState([
    { id: 101, name: "Alice", role: "Admin", isSelected: true },
    { id: 102, name: "Bob", role: "User", isSelected: false },
    { id: 103, name: "Charlie", role: "Manager", isSelected: true },
  ]);

  const [columnDefs] = useState([
    {
      headerName: "ID",
      field: "id",
      checkboxSelection: true,
      headerCheckboxSelection: true,
    },
    { headerName: "Name", field: "name" },
    { headerName: "Role", field: "role" },
  ]);

  // ✅ selectedUsers can be an empty array now
  const validationSchema = Yup.object({
    name: Yup.string().required("Name is required"),
    description: Yup.string().required("Description is required"),
    selectedUsers: Yup.array().nullable(),
  });

  const initialValues = selectedRecord || {
    name: "",
    description: "",
    selectedUsers: [],
  };

  const formik = useFormik({
    initialValues,
    enableReinitialize: true,
    validationSchema,
    onSubmit: async (values, { resetForm }) => {
      try {
        console.log("Form Submitted:", values);
        await new Promise((res) => setTimeout(res, 1000));
        setSubmitMessage("Form submitted successfully!");
        setShowForm(false);
        resetForm();
      } catch (error) {
        setSubmitMessage("Error submitting form");
      }
    },
  });

  const handleSearch = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (value.length > 1) {
      const results = await fetchSearchResults(value);
      setSearchResults(results);
    } else {
      setSearchResults([]);
    }
  };

  const handleSelect = (record: any) => {
    setSelectedRecord(record);
    setShowForm(true);
    setSubmitMessage("");
  };

  const handlePreSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errors = await formik.validateForm();
    formik.setTouched({
      name: true,
      description: true,
      selectedUsers: true,
    });
    if (Object.keys(errors).length === 0) {
      setShowModal(true);
    }
  };

  const handleAccept = () => {
    setShowModal(false);
    formik.handleSubmit();
  };

  const handleReject = () => setShowModal(false);

  // ✅ Pre-check rows based on isSelected
  const onGridReady = (params: any) => {
    params.api.forEachNode((node: any) => {
      if (node.data.isSelected) {
        node.setSelected(true);
      }
    });
  };

  // ✅ Save selection and sync with rowData
  const handleSaveGridSelection = () => {
    const selectedRows = gridRef.current?.api.getSelectedRows() || [];

    // Update formik values
    formik.setFieldValue("selectedUsers", selectedRows);

    // Sync isSelected state
    const updatedRowData = rowData.map((row) => ({
      ...row,
      isSelected: selectedRows.some((sel) => sel.id === row.id),
    }));
    setRowData(updatedRowData);

    setShowGridModal(false);
  };

  return (
    <div className="p-4">
      <h2>Search & Update Form</h2>

      {/* Search Box */}
      <input
        type="text"
        placeholder="Search..."
        onChange={handleSearch}
        className="border p-2 my-2"
      />
      <ul className="border p-2">
        {searchResults.map((r) => (
          <li
            key={r.id}
            onClick={() => handleSelect(r)}
            className="cursor-pointer hover:bg-gray-100 p-1"
          >
            {r.name} - {r.description}
          </li>
        ))}
      </ul>

      {/* Success / Error Message */}
      {submitMessage && (
        <div className="mt-2 text-green-600 font-semibold">{submitMessage}</div>
      )}

      {/* Form */}
      {showForm && selectedRecord && (
        <form onSubmit={handlePreSubmit} className="mt-4">
          <div>
            <label>Name</label>
            <input
              name="name"
              value={formik.values.name}
              onChange={formik.handleChange}
              onBlur={formik.handleBlur}
              className="border p-1 block"
            />
            {formik.touched.name && formik.errors.name && (
              <div className="text-red-500">{formik.errors.name}</div>
            )}
          </div>

          <div>
            <label>Description</label>
            <input
              name="description"
              value={formik.values.description}
              onChange={formik.handleChange}
              onBlur={formik.handleBlur}
              className="border p-1 block"
            />
            {formik.touched.description && formik.errors.description && (
              <div className="text-red-500">{formik.errors.description}</div>
            )}
          </div>

          {/* AG Grid Selector */}
          <div className="mt-2">
            <button
              type="button"
              className="bg-gray-200 px-2"
              onClick={() => setShowGridModal(true)}
            >
              Select Users
            </button>
            {formik.values.selectedUsers.length > 0 && (
              <ul className="list-disc pl-5 mt-2 text-sm text-gray-600">
                {formik.values.selectedUsers.map((u: any) => (
                  <li key={u.id}>
                    {u.name} - {u.role}
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="flex gap-2 mt-3">
            <button type="submit" disabled={formik.isSubmitting}>
              {formik.isSubmitting ? "Submitting..." : "Submit"}
            </button>
            <button
              type="button"
              onClick={() => formik.resetForm({ values: initialValues })}
            >
              Reset
            </button>
          </div>
        </form>
      )}

      {/* Terms & Conditions Modal */}
      {showModal && (
        <div className="fixed inset-0 flex items-center justify-center bg-black/50">
          <div className="bg-white p-4 rounded shadow-lg w-80">
            <h3 className="font-bold mb-2">Terms & Conditions</h3>
            <p>Please accept our terms before submitting the form.</p>
            <div className="flex justify-end gap-2 mt-4">
              <button onClick={handleReject} className="border px-3 py-1">
                Reject
              </button>
              <button
                onClick={handleAccept}
                className="bg-blue-500 text-white px-3 py-1"
              >
                Accept
              </button>
            </div>
          </div>
        </div>
      )}

      {/* AG Grid Modal */}
      {showGridModal && (
        <div className="fixed inset-0 flex items-center justify-center bg-black/50">
          <div className="bg-white p-4 rounded shadow-lg w-[600px] h-[400px] flex flex-col">
            <h3 className="font-bold mb-2">Select Users</h3>
            <div className="ag-theme-alpine flex-1">
              <AgGridReact
                ref={gridRef}
                rowData={rowData}
                columnDefs={columnDefs}
                rowSelection="multiple"
                onGridReady={onGridReady}
              />
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setShowGridModal(false)}
                className="border px-3 py-1"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveGridSelection}
                className="bg-blue-500 text-white px-3 py-1"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
